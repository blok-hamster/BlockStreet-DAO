// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Certificate.sol";

contract NewSchool is Ownable {

    using SafeMath for uint;

    event CourseAddes(string indexed courseTitle, string indexed courseDescription, uint indexed time);
    event CourseStateChanged(string indexed courseTitle, bool indexed state, uint indexed time);
    event StudentAdded(address indexed student, uint indexed studentId, uint indexed time);
    event CourseStarted(address indexed student, string indexed courseTitle, uint indexed time);
    event TestStarted(string indexed courseTitle, address indexed student, uint indexed time);
    event TestPassed(string indexed courseTitle, address indexed student, uint indexed time);
    event TestFailed(string indexed courseTitle, address indexed student, uint indexed time);
    event CourseCompleted(string indexed courseTitle, address indexed student, uint indexed time);
    event CertificateClaimed(address indexed student, string indexed courseTitle, uint indexed time);
    event TestRewardClaimed(address indexed student, uint indexed time);


    enum Status {
        PASS,
        FAIL
    }

    struct Test {
        string courseTitle;
        address tutor;
        address student;
        string result;
    }

    struct Course {
        string courseTitle;
        string description;
        address tutor;
        uint courseId;
        uint courseStudentCount;
    }

    struct Student{
        address addr;
        uint StudentId;
        uint courseStartedCounter;
        uint certificateCounter;
    }

    struct Certificate{
        address holder;
        address tutor;
        string courseTitle;
        bytes32 certificateHash;
        string message;
    }

    mapping (address => bool) isStudent;
    mapping (address => bool) isTutor; 
    mapping (string => bool) courseStarted;
    mapping (address => Student) studentMap;
    mapping (string => Course) courseMap;
    mapping (address => string[]) studentCourse;
    mapping (string => Test) testMap;
    mapping (address => mapping (string => bool)) hasTakenTest;
    mapping (address => Test[]) studentTest;
    mapping (address => Certificate) certificateMap;
    mapping (address => uint) rewardBalanceMapping;
    mapping (address => mapping (string => Status)) testResultMap;
    mapping (address => mapping (string => bytes32)) certificateHashMap;
    mapping (string => BlockStreetCert) certificateNft;
    mapping (string => uint) nextTokenId;
    mapping (address => mapping (string => bool)) studentCompletedCourse;
    mapping (address => mapping (string => bool)) studentStartedCourse;
    mapping (address => mapping (string => bool)) testRewardClaimed;

    string[] courseList;
    address[] studentList;
    uint nextCourseId;
    uint private testReward;
    address rewardToken;

    modifier onlyStudent(){
        require(isStudent[msg.sender] == true, "Sign Up");
        _;
    }
 
    function addCourse(string memory _courseTitle, string memory _description, address _tutor) external onlyOwner {
        require(_tutor != address(0));
        courseMap[_courseTitle] = Course(_courseTitle, _description, _tutor, nextCourseId, 0);
        isTutor[_tutor] = true;
        courseStarted[_courseTitle] = false;
        courseList.push(_courseTitle);
        nextCourseId++;
        courseStarted[_courseTitle] = true;

        BlockStreetCert blockCert = new BlockStreetCert(_courseTitle, address(this), _tutor);
        certificateNft[_courseTitle] = blockCert;

        emit CourseAddes(_courseTitle, _description, block.timestamp);
    }

    function changeCourseState(string memory _courseTitle) public onlyOwner {
        if(courseStarted[_courseTitle] == false){
            courseStarted[_courseTitle] = true;
        }
        else if(courseStarted[_courseTitle] == true){
            courseStarted[_courseTitle] = false;
        }
        emit CourseStateChanged(_courseTitle, courseStarted[_courseTitle], block.timestamp);
    }

    function joinSchool() external {
        require(isStudent[msg.sender] == false);
        studentMap[msg.sender] = Student(msg.sender, studentList.length, 0, 0);
        isStudent[msg.sender] = true;
        studentList.push(msg.sender);

        emit StudentAdded(msg.sender, studentList.length, block.timestamp);
    }

    function startCourse(string memory _courseTitle) external onlyStudent() { 
        require(courseStarted[_courseTitle] == true, "Course Not active");
        string[] storage newCourse = studentCourse[msg.sender];
        newCourse.push(_courseTitle);
        studentStartedCourse[msg.sender][_courseTitle] = true;
        studentMap[msg.sender].courseStartedCounter++;
        courseMap[_courseTitle].courseStudentCount++;

        emit CourseStarted(msg.sender, _courseTitle, block.timestamp);
    }

    function takeTest(string memory _courseTitle) external onlyStudent {
        require(studentStartedCourse[msg.sender][_courseTitle] == true, "Go Start A Course");
        hasTakenTest[msg.sender][_courseTitle] = true;
        
        emit TestStarted(_courseTitle, msg.sender, block.timestamp);
    }

    function submitTest(string memory _courseTitle, Status status) external onlyStudent(){
        Test[] storage newTest = studentTest[msg.sender];
        require(hasTakenTest[msg.sender][_courseTitle] == true, "You Have To Take The Test");
        require(testRewardClaimed[msg.sender][_courseTitle] == false);
        if(status == Status.PASS){
            Test(_courseTitle, courseMap[_courseTitle].tutor, msg.sender, "PASS");
            newTest.push(Test(_courseTitle, courseMap[_courseTitle].tutor, msg.sender, "PASS"));
            rewardBalanceMapping[msg.sender] = rewardBalanceMapping[msg.sender].add(testReward);
            testRewardClaimed[msg.sender][_courseTitle] = true;
            emit TestPassed(_courseTitle, msg.sender, block.timestamp);
        }

        else if(status == Status.FAIL){
            Test(_courseTitle, courseMap[_courseTitle].tutor, msg.sender, "FAIL");
            newTest.push(Test(_courseTitle, courseMap[_courseTitle].tutor, msg.sender, "FAIL"));

            emit TestFailed(_courseTitle, msg.sender, block.timestamp);
        }

    }

    function complete(string memory _courseTitle) external onlyStudent() {
        require(studentStartedCourse[msg.sender][_courseTitle] == true, "Go Start A Course");
        studentCompletedCourse[msg.sender][_courseTitle] = true;

        emit CourseCompleted(_courseTitle, msg.sender, block.timestamp);
   }

    function claimCertificate(string memory _courseTitle) external onlyStudent() returns(bytes32) {
        require(studentCompletedCourse[msg.sender][_courseTitle] == true, "Complete the course and take the test");
        require(hasTakenTest[msg.sender][_courseTitle] == true, "You Have To Take The Test");
        
        bytes32 certHash = keccak256(abi.encodePacked(
        _courseTitle, 
        msg.sender, 
        studentMap[msg.sender].StudentId, 
        courseMap[_courseTitle].tutor, 
        block.timestamp));
        
        certificateHashMap[msg.sender][_courseTitle] = certHash;
        certificateMap[msg.sender] = Certificate(msg.sender, 
        courseMap[_courseTitle].tutor, 
        _courseTitle, 
        certHash, "Congratulation You Made It");
        studentMap[msg.sender].certificateCounter++;

        uint tokenId = nextTokenId[_courseTitle];

        BlockStreetCert(certificateNft[_courseTitle]).mint(msg.sender, tokenId, 1, "");
        BlockStreetCert(certificateNft[_courseTitle]).AddHolders(msg.sender);
        BlockStreetCert(certificateNft[_courseTitle]).incraseCertHolders();

        tokenId++;

        return certHash;
        emit CertificateClaimed(msg.sender, _courseTitle, block.timestamp);
    }

    function claimReward() external onlyStudent() {
        require(rewardBalanceMapping[msg.sender] > 0, "No rewards to claim");
        IERC20(rewardToken).transfer(msg.sender, rewardBalanceMapping[msg.sender]);

        emit TestRewardClaimed(msg.sender, block.timestamp);
   }

   function verifyCertificate(bytes32 _certHash, string memory _courseTitle) external view returns(string memory success){
       if(certificateHashMap[msg.sender][_courseTitle] == _certHash){
           return "VERIFICATION PASSED";
       } 
       else if(certificateHashMap[msg.sender][_courseTitle] != _certHash) {
           return "INVALID CERTIFICATE";
       }
   }

   function updateTestRewards(uint _amount) external onlyOwner {
       testReward = _amount;
   }

   function getTestRewardBalance() external view onlyStudent returns(uint balance){
       return rewardBalanceMapping[msg.sender];
   }

   function getCourseList() external view returns(string[] memory){
       return courseList;
   }

   function getStudentList() external view onlyOwner returns(address[] memory) {
       return studentList;
   }

    function getCourse(string memory _courseTitle) external view returns(Course memory){
       return courseMap[_courseTitle];
   }

   function getCetificate() external view onlyStudent returns(Certificate memory){
       return certificateMap[msg.sender];
   }

   function getCertHash(string memory _courseTitle) external view onlyStudent{
       certificateHashMap[msg.sender][_courseTitle];
   }

   function getNftCert(string memory _courseTitle, uint _id) external view onlyStudent{
       BlockStreetCert(certificateNft[_courseTitle]).getBalanceOf(msg.sender, _id);
   }
}