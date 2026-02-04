"""
ITI Database - Egyptian Mock Data Insertion Script
Uses SQL Server connection string to insert Egyptian-themed mock data directly into database
"""

import pyodbc
import random
import argparse
from datetime import datetime, timedelta
from typing import List, Dict, Any

# ============================================================================
# EGYPTIAN DATA SETS
# ============================================================================

EGYPTIAN_FIRST_NAMES_MALE = [
    "Mohamed", "Ahmed", "Mahmoud", "Abdelrahman", "Omar", "Youssef", "Karim",
    "Hassan", "Ali", "Amr", "Khaled", "Mostafa", "Tamer", "Sherif", "Hossam",
    "Tarek", "Adel", "Eslam", "Ibrahim", "Abdallah", "Hesham", "Hany", "Sayed",
    "Hamza", "Osama", "Waleed", "Magdy", "Ashraf", "Gamal", "Samir"
]

EGYPTIAN_FIRST_NAMES_FEMALE = [
    "Fatma", "Mariam", "Nour", "Yasmin", "Sara", "Salma", "Hana", "Aya",
    "Menna", "Dina", "Heba", "Noha", "Rana", "Mai", "Reem", "Laila",
    "Amira", "Nada", "Nesma", "Hagar", "Doaa", "Eman", "Safaa", "Somaya"
]

EGYPTIAN_LAST_NAMES = [
    "Mohamed", "Ahmed", "Hassan", "Ali", "Abdel-Aziz", "Mahmoud", "Ibrahim",
    "Mostafa", "Youssef", "Said", "Salem", "Farid", "Naguib", "Ramadan",
    "El-Sayed", "Mansour", "Khalil", "Amin", "Morsi", "Fathy", "Bakr",
    "Ezz", "Shaaban", "Gaber", "Nasr", "Helmy", "Abdo", "Othman"
]

DEPARTMENTS = [
    "Computer Science", "Information Technology", "Software Engineering",
    "Data Science", "Artificial Intelligence"
]

TRACKS = [
    "Web Development", "Mobile Development", "Data Science",
    "AI & Machine Learning", "Cybersecurity", "DevOps",
    "Cloud Computing", "Game Development"
]

JOB_PROFILES = [
    "Backend Developer", "Frontend Developer", "Full Stack Developer",
    "Data Scientist", "Machine Learning Engineer", "DevOps Engineer",
    "Database Administrator", "Security Analyst", "Mobile Developer",
    "Cloud Architect", "UI/UX Designer"
]

COURSES = [
    "Database Management Systems", "Data Structures", "Algorithms",
    "Web Development", "Machine Learning", "Computer Networks",
    "Operating Systems", "Software Engineering", "Artificial Intelligence",
    "Cloud Computing", "Cybersecurity", "Mobile Development"
]

TOPICS = [
    "SQL Basics", "Normalization", "Stored Procedures", "Transactions",
    "Indexing", "Joins", "Triggers", "Views", "Binary Trees", "Graphs",
    "Sorting Algorithms", "Dynamic Programming", "HTML/CSS", "JavaScript",
    "React", "Node.js", "Python Basics", "Neural Networks", "Docker", "Kubernetes"
]

# ============================================================================
# REAL QUESTIONS BANK - Organized by Course
# ============================================================================

QUESTION_BANK = {
    "Database Management Systems": {
        "MCQ": [
            {"q": "What does SQL stand for?", "choices": ["Structured Query Language", "Simple Question Language", "Sequential Query Logic", "Standard Query Library"], "correct": 0, "difficulty": "Easy", "points": 1},
            {"q": "Which SQL clause is used to filter rows?", "choices": ["SELECT", "WHERE", "FROM", "GROUP BY"], "correct": 1, "difficulty": "Easy", "points": 2},
            {"q": "What is the purpose of a PRIMARY KEY?", "choices": ["Speed up queries", "Uniquely identify each row", "Sort data", "Link tables"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "Which normal form eliminates transitive dependencies?", "choices": ["1NF", "2NF", "3NF", "BCNF"], "correct": 2, "difficulty": "Medium", "points": 3},
            {"q": "What type of join returns all rows from both tables?", "choices": ["INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL OUTER JOIN"], "correct": 3, "difficulty": "Medium", "points": 2},
            {"q": "Which SQL command is used to modify existing data?", "choices": ["INSERT", "UPDATE", "ALTER", "MODIFY"], "correct": 1, "difficulty": "Easy", "points": 1},
            {"q": "What is a foreign key constraint used for?", "choices": ["Ensure data integrity", "Speed up queries", "Create indexes", "Define primary keys"], "correct": 0, "difficulty": "Medium", "points": 2},
            {"q": "Which isolation level prevents dirty reads?", "choices": ["READ UNCOMMITTED", "READ COMMITTED", "REPEATABLE READ", "SERIALIZABLE"], "correct": 1, "difficulty": "Hard", "points": 3},
        ],
        "TF": [
            {"q": "A database can have multiple tables with the same name", "answer": False, "difficulty": "Easy", "points": 1},
            {"q": "Stored procedures can improve database performance", "answer": True, "difficulty": "Medium", "points": 2},
            {"q": "NULL and 0 are the same in SQL", "answer": False, "difficulty": "Medium", "points": 2},
            {"q": "Triggers can be executed automatically on INSERT, UPDATE, or DELETE operations", "answer": True, "difficulty": "Medium", "points": 2},
        ]
    },
    
    "Data Structures": {
        "MCQ": [
            {"q": "What is the time complexity of binary search?", "choices": ["O(n)", "O(log n)", "O(n log n)", "O(1)"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "Which data structure uses LIFO (Last In First Out)?", "choices": ["Queue", "Stack", "Tree", "Graph"], "correct": 1, "difficulty": "Easy", "points": 1},
            {"q": "What is the worst-case time complexity for insertion in a hash table?", "choices": ["O(1)", "O(log n)", "O(n)", "O(n²)"], "correct": 2, "difficulty": "Hard", "points": 3},
            {"q": "In a binary tree, what is a node with no children called?", "choices": ["Root", "Leaf", "Parent", "Sibling"], "correct": 1, "difficulty": "Easy", "points": 1},
            {"q": "Which traversal visits nodes in ascending order in a BST?", "choices": ["Pre-order", "Post-order", "In-order", "Level-order"], "correct": 2, "difficulty": "Medium", "points": 2},
            {"q": "What is the maximum number of children in a binary tree node?", "choices": ["1", "2", "3", "Unlimited"], "correct": 1, "difficulty": "Easy", "points": 1},
        ],
        "TF": [
            {"q": "Arrays have fixed size in most programming languages", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "Linked lists provide constant time random access", "answer": False, "difficulty": "Medium", "points": 2},
            {"q": "A queue follows First In First Out (FIFO) principle", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "All binary search trees are balanced", "answer": False, "difficulty": "Medium", "points": 2},
        ]
    },
    
    "Algorithms": {
        "MCQ": [
            {"q": "What is the time complexity of Quick Sort on average?", "choices": ["O(n)", "O(n log n)", "O(n²)", "O(log n)"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "Which algorithm is used to find the shortest path in a graph?", "choices": ["DFS", "BFS", "Dijkstra's", "Kruskal's"], "correct": 2, "difficulty": "Medium", "points": 3},
            {"q": "Which sorting algorithm is most efficient for nearly sorted data?", "choices": ["Bubble Sort", "Insertion Sort", "Merge Sort", "Quick Sort"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "What technique does Dynamic Programming use?", "choices": ["Divide and Conquer", "Greedy Choice", "Memoization", "Backtracking"], "correct": 2, "difficulty": "Hard", "points": 3},
            {"q": "Which algorithm finds the Minimum Spanning Tree?", "choices": ["Dijkstra's", "Prim's", "Binary Search", "Linear Search"], "correct": 1, "difficulty": "Medium", "points": 2},
        ],
        "TF": [
            {"q": "Bubble Sort has O(n²) time complexity in the worst case", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "Binary search works on unsorted arrays", "answer": False, "difficulty": "Easy", "points": 1},
            {"q": "Merge sort is a stable sorting algorithm", "answer": True, "difficulty": "Medium", "points": 2},
            {"q": "Greedy algorithms always find the optimal solution", "answer": False, "difficulty": "Hard", "points": 3},
        ]
    },
    
    "Web Development": {
        "MCQ": [
            {"q": "What does HTML stand for?", "choices": ["Hyper Text Markup Language", "High Tech Modern Language", "Home Tool Markup Language", "Hyperlinks Text Mark Language"], "correct": 0, "difficulty": "Easy", "points": 1},
            {"q": "Which CSS property is used to change text color?", "choices": ["font-color", "text-color", "color", "fg-color"], "correct": 2, "difficulty": "Easy", "points": 1},
            {"q": "Which JavaScript method is used to select an element by ID?", "choices": ["querySelector()", "getElementById()", "getElement()", "selectById()"], "correct": 1, "difficulty": "Easy", "points": 1},
            {"q": "What is the default HTTP method for HTML forms?", "choices": ["POST", "GET", "PUT", "DELETE"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "Which HTML tag is used for creating hyperlinks?", "choices": ["<link>", "<a>", "<href>", "<url>"], "correct": 1, "difficulty": "Easy", "points": 1},
            {"q": "What is the CSS Box Model?", "choices": ["Content, Padding, Border, Margin", "Header, Body, Footer", "Width, Height, Depth", "Font, Size, Color"], "correct": 0, "difficulty": "Medium", "points": 2},
        ],
        "TF": [
            {"q": "CSS stands for Cascading Style Sheets", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "JavaScript is the same as Java", "answer": False, "difficulty": "Easy", "points": 1},
            {"q": "HTML5 introduced semantic elements like <header> and <footer>", "answer": True, "difficulty": "Medium", "points": 2},
            {"q": "The <div> tag has semantic meaning", "answer": False, "difficulty": "Medium", "points": 2},
        ]
    },
    
    "Machine Learning": {
        "MCQ": [
            {"q": "Which type of learning uses labeled data?", "choices": ["Unsupervised Learning", "Supervised Learning", "Reinforcement Learning", "Semi-supervised Learning"], "correct": 1, "difficulty": "Easy", "points": 2},
            {"q": "What is overfitting in machine learning?", "choices": ["Model is too simple", "Model performs well on training data but poorly on new data", "Model has too few parameters", "Model trains too quickly"], "correct": 1, "difficulty": "Medium", "points": 3},
            {"q": "Which algorithm is used for classification?", "choices": ["Linear Regression", "Logistic Regression", "K-Means", "PCA"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "What does k in k-NN algorithm represent?", "choices": ["Number of features", "Number of nearest neighbors", "Number of clusters", "Number of iterations"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "Which activation function is commonly used in hidden layers?", "choices": ["Sigmoid", "ReLU", "Linear", "Softmax"], "correct": 1, "difficulty": "Medium", "points": 2},
        ],
        "TF": [
            {"q": "Deep Learning is a subset of Machine Learning", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "K-Means is a supervised learning algorithm", "answer": False, "difficulty": "Medium", "points": 2},
            {"q": "Feature scaling can improve model performance", "answer": True, "difficulty": "Medium", "points": 2},
            {"q": "Neural networks always outperform traditional algorithms", "answer": False, "difficulty": "Hard", "points": 3},
        ]
    },
    
    "Computer Networks": {
        "MCQ": [
            {"q": "Which layer of OSI model handles routing?", "choices": ["Data Link", "Network", "Transport", "Application"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "What protocol is used for sending emails?", "choices": ["HTTP", "FTP", "SMTP", "POP3"], "correct": 2, "difficulty": "Easy", "points": 1},
            {"q": "What is the default port number for HTTP?", "choices": ["21", "25", "80", "443"], "correct": 2, "difficulty": "Medium", "points": 2},
            {"q": "Which protocol ensures reliable data transmission?", "choices": ["IP", "UDP", "TCP", "ICMP"], "correct": 2, "difficulty": "Medium", "points": 2},
            {"q": "What does DNS stand for?", "choices": ["Dynamic Name System", "Domain Name System", "Data Network Service", "Digital Name Server"], "correct": 1, "difficulty": "Easy", "points": 1},
        ],
        "TF": [
            {"q": "IP address uniquely identifies a device on a network", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "UDP provides guaranteed delivery of packets", "answer": False, "difficulty": "Medium", "points": 2},
            {"q": "HTTPS is more secure than HTTP", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "MAC address operates at the Network layer", "answer": False, "difficulty": "Medium", "points": 2},
        ]
    },
    
    "Operating Systems": {
        "MCQ": [
            {"q": "What is the main function of an operating system?", "choices": ["Internet browsing", "Resource management", "Gaming", "File editing"], "correct": 1, "difficulty": "Easy", "points": 1},
            {"q": "Which scheduling algorithm can cause starvation?", "choices": ["FCFS", "Round Robin", "SJF", "Priority"], "correct": 3, "difficulty": "Hard", "points": 3},
            {"q": "What is a deadlock?", "choices": ["System crash", "Process waiting indefinitely for resources", "Memory leak", "CPU overload"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "Which memory management technique divides memory into fixed-size blocks?", "choices": ["Paging", "Segmentation", "Swapping", "Caching"], "correct": 0, "difficulty": "Hard", "points": 3},
            {"q": "What is the purpose of virtual memory?", "choices": ["Faster processing", "Extend physical memory", "Improve graphics", "Network communication"], "correct": 1, "difficulty": "Medium", "points": 2},
        ],
        "TF": [
            {"q": "A process and a thread are the same thing", "answer": False, "difficulty": "Medium", "points": 2},
            {"q": "Context switching has overhead", "answer": True, "difficulty": "Medium", "points": 2},
            {"q": "All deadlocks can be prevented", "answer": False, "difficulty": "Hard", "points": 3},
            {"q": "The kernel is the core part of an operating system", "answer": True, "difficulty": "Easy", "points": 1},
        ]
    },
    
    "Software Engineering": {
        "MCQ": [
            {"q": "Which software development model emphasizes iterative development?", "choices": ["Waterfall", "Agile", "Spiral", "V-Model"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "What does UML stand for?", "choices": ["Universal Markup Language", "Unified Modeling Language", "User Mode Logic", "Uniform Method Library"], "correct": 1, "difficulty": "Easy", "points": 1},
            {"q": "Which testing level focuses on individual units?", "choices": ["Integration Testing", "System Testing", "Unit Testing", "Acceptance Testing"], "correct": 2, "difficulty": "Easy", "points": 1},
            {"q": "What is refactoring?", "choices": ["Adding new features", "Rewriting code from scratch", "Improving code structure without changing behavior", "Fixing bugs"], "correct": 2, "difficulty": "Medium", "points": 2},
            {"q": "Which SOLID principle states that classes should have one reason to change?", "choices": ["Open/Closed", "Single Responsibility", "Liskov Substitution", "Interface Segregation"], "correct": 1, "difficulty": "Medium", "points": 2},
        ],
        "TF": [
            {"q": "Version control systems help track code changes", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "Waterfall model allows going back to previous phases easily", "answer": False, "difficulty": "Medium", "points": 2},
            {"q": "Code reviews can improve software quality", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "Design patterns are specific implementations", "answer": False, "difficulty": "Medium", "points": 2},
        ]
    },
    
    "Artificial Intelligence": {
        "MCQ": [
            {"q": "What is the Turing Test used for?", "choices": ["Measuring computer speed", "Determining if a machine exhibits intelligent behavior", "Testing network latency", "Evaluating algorithm efficiency"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "Which search algorithm uses a heuristic function?", "choices": ["BFS", "DFS", "A*", " Uniform Cost Search"], "correct": 2, "difficulty": "Hard", "points": 3},
            {"q": "What type of AI learns from trial and error?", "choices": ["Supervised Learning", "Unsupervised Learning", "Reinforcement Learning", "Transfer Learning"], "correct": 2, "difficulty": "Medium", "points": 2},
            {"q": "What is backpropagation used for?", "choices": ["Data preprocessing", "Training neural networks", "Feature selection", "Model deployment"], "correct": 1, "difficulty": "Medium", "points": 2},
        ],
        "TF": [
            {"q": "Neural networks are inspired by the human brain", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "AI and Machine Learning are the same", "answer": False, "difficulty": "Easy", "points": 1},
            {"q": "Natural Language Processing is a branch of AI", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "Expert systems use predefined rules", "answer": True, "difficulty": "Medium", "points": 2},
        ]
    },
    
    "Cloud Computing": {
        "MCQ": [
            {"q": "Which cloud service model provides infrastructure?", "choices": ["SaaS", "PaaS", "IaaS", "FaaS"], "correct": 2, "difficulty": "Medium", "points": 2},
            {"q": "What does AWS stand for?", "choices": ["Amazon Web Services", "Advanced Web System", "Automatic Web Service", "Amazon Wireless System"], "correct": 0, "difficulty": "Easy", "points": 1},
            {"q": "Which deployment model is owned by a single organization?", "choices": ["Public Cloud", "Private Cloud", "Hybrid Cloud", "Community Cloud"], "correct": 1, "difficulty": "Easy", "points": 1},
            {"q": "What is auto-scaling in cloud computing?", "choices": ["Automatic backup", "Automatic resource adjustment", "Automatic deployment", "Automatic monitoring"], "correct": 1, "difficulty": "Medium", "points": 2},
        ],
        "TF": [
            {"q": "Cloud computing eliminates the need for data centers", "answer": False, "difficulty": "Medium", "points": 2},
            {"q": "Virtualization is a key technology in cloud computing", "answer": True, "difficulty": "Medium", "points": 2},
            {"q": "All cloud services are free", "answer": False, "difficulty": "Easy", "points": 1},
            {"q": "Cloud storage can be accessed from anywhere with internet", "answer": True, "difficulty": "Easy", "points": 1},
        ]
    },
    
    "Cybersecurity": {
        "MCQ": [
            {"q": "What does CIA triad stand for in security?", "choices": ["Confidentiality, Integrity, Availability", "Control, Inspection, Analysis", "Centralized, Integrated, Automated", "Cloud, Infrastructure, Applications"], "correct": 0, "difficulty": "Medium", "points": 2},
            {"q": "Which attack involves flooding a server with traffic?", "choices": ["Phishing", "DDoS", "SQL Injection", "Man-in-the-Middle"], "correct": 1, "difficulty": "Easy", "points": 1},
            {"q": "What is encryption used for?", "choices": ["Speed up data transfer", "Protect data confidentiality", "Compress files", "Monitor network"], "correct": 1, "difficulty": "Easy", "points": 1},
            {"q": "Which protocol provides secure communication over networks?", "choices": ["HTTP", "FTP", "SSL/TLS", "SMTP"], "correct": 2, "difficulty": "Medium", "points": 2},
        ],
        "TF": [
            {"q": "Firewalls can block unauthorized access", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "Two-factor authentication is less secure than passwords alone", "answer": False, "difficulty": "Easy", "points": 1},
            {"q": "Social engineering exploits human psychology", "answer": True, "difficulty": "Medium", "points": 2},
            {"q": "Antivirus software can detect all types of malware", "answer": False, "difficulty": "Medium", "points": 2},
        ]
    },
    
    "Mobile Development": {
        "MCQ": [
            {"q": "Which language is primarily used for Android development?", "choices": ["Swift", "Kotlin", "C#", "Ruby"], "correct": 1, "difficulty": "Easy", "points": 1},
            {"q": "What is the main advantage of React Native?", "choices": ["Better performance", "Cross-platform development", "Smaller app size", "More features"], "correct": 1, "difficulty": "Medium", "points": 2},
            {"q": "Which company developed Swift programming language?", "choices": ["Google", "Microsoft", "Apple", "Facebook"], "correct": 2, "difficulty": "Easy", "points": 1},
            {"q": "What is an APK file?", "choices": ["Android Package Kit", "Application Programming Key", "Advanced Plugin Kit", "App Performance Kernel"], "correct": 0, "difficulty": "Easy", "points": 1},
        ],
        "TF": [
            {"q": "iOS apps can run on Android devices", "answer": False, "difficulty": "Easy", "points": 1},
            {"q": "Mobile apps can access device sensors", "answer": True, "difficulty": "Easy", "points": 1},
            {"q": "Flutter uses JavaScript for development", "answer": False, "difficulty": "Medium", "points": 2},
            {"q": "Push notifications can work when app is closed", "answer": True, "difficulty": "Medium", "points": 2},
        ]
    }
}


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def generate_phone():
    """Generate Egyptian phone number (format: 01X XXXXXXXX)"""
    return f"01{random.choice([0, 1, 2, 5])}{random.randint(10000000, 99999999)}"

def generate_email(first_name, last_name):
    """Generate email address"""
    domains = ["gmail.com", "yahoo.com", "outlook.com", "iti.edu.eg", "hotmail.com"]
    return f"{first_name.lower()}.{last_name.lower()}{random.randint(1, 999)}@{random.choice(domains)}"

def get_random_name(gender):
    """Get random Egyptian name based on gender"""
    if gender == 'M':
        first_name = random.choice(EGYPTIAN_FIRST_NAMES_MALE)
    else:
        first_name = random.choice(EGYPTIAN_FIRST_NAMES_FEMALE)
    last_name = random.choice(EGYPTIAN_LAST_NAMES)
    return first_name, last_name

# ============================================================================
# DATABASE CONNECTION
# ============================================================================

class DatabaseConnection:
    def __init__(self, connection_string):
        self.connection_string = connection_string
        self.conn = None
        self.cursor = None
    
    def connect(self):
        """Establish database connection"""
        try:
            self.conn = pyodbc.connect(self.connection_string)
            self.cursor = self.conn.cursor()
            print("✅ Database connection established successfully!")
            return True
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            return False
    
    def close(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        print("🔒 Database connection closed.")
    
    def commit(self):
        """Commit transaction"""
        if self.conn:
            self.conn.commit()
    
    def rollback(self):
        """Rollback transaction"""
        if self.conn:
            self.conn.rollback()

# ============================================================================
# DATA INSERTION FUNCTIONS
# ============================================================================

def clear_tables(db: DatabaseConnection):
    """Clear all tables in reverse dependency order"""
    print("\n🗑️  Clearing existing data...")
    
    tables = [
        "Student_Answer", "Student_Exam", "Exam_Questions", "Choice", "Question",
        "Exam", "Teaching", "Student_Course", "Course_Topic", "Student_Phones",
        "Student", "Instructor_Phones", "Instructor", "Topic", "Course",
        "Track_JobProfile", "Track", "Department"
    ]
    
    try:
        for table in tables:
            db.cursor.execute(f"DELETE FROM {table}")
            print(f"   Cleared {table}")
        db.commit()
        print("✅ All tables cleared successfully!")
    except Exception as e:
        print(f"❌ Error clearing tables: {e}")
        db.rollback()
        raise

def insert_departments(db: DatabaseConnection):
    """Insert Department data"""
    print("\n📊 Inserting Departments...")
    departments = []
    
    for i, dept_name in enumerate(DEPARTMENTS, 1):
        db.cursor.execute(
            "INSERT INTO Department (D_Id, D_Name) VALUES (?, ?)",
            (i, dept_name)
        )
        departments.append({'D_Id': i, 'D_Name': dept_name})
    
    db.commit()
    print(f"   ✅ Inserted {len(departments)} departments")
    return departments

def insert_tracks(db: DatabaseConnection, departments):
    """Insert Track data"""
    print("\n🛤️  Inserting Tracks...")
    tracks = []
    
    for i, track_name in enumerate(TRACKS, 1):
        dep_id = random.randint(1, len(departments))
        db.cursor.execute(
            "INSERT INTO Track (Track_Id, Track_Name, Track_Des, Dep_Id) VALUES (?, ?, ?, ?)",
            (i, track_name, f"Specialized training in {track_name}", dep_id)
        )
        tracks.append({'Track_Id': i, 'Track_Name': track_name, 'Dep_Id': dep_id})
    
    db.commit()
    print(f"   ✅ Inserted {len(tracks)} tracks")
    return tracks

def insert_track_job_profiles(db: DatabaseConnection, tracks):
    """Insert Track_JobProfile data"""
    print("\n💼 Inserting Track Job Profiles...")
    count = 0
    
    for track in tracks:
        num_jobs = random.randint(2, 4)
        selected_jobs = random.sample(JOB_PROFILES, min(num_jobs, len(JOB_PROFILES)))
        for job in selected_jobs:
            db.cursor.execute(
                "INSERT INTO Track_JobProfile (Track_Id, T_JobProfiles) VALUES (?, ?)",
                (track['Track_Id'], job)
            )
            count += 1
    
    db.commit()
    print(f"   ✅ Inserted {count} job profiles")

def insert_instructors(db: DatabaseConnection, departments, num_instructors=20):
    """Insert Instructor data"""
    print(f"\n👨‍🏫 Inserting {num_instructors} Instructors...")
    instructors = []
    
    for i in range(1, num_instructors + 1):
        gender = random.choice(['M', 'F'])
        first_name, last_name = get_random_name(gender)
        
        db.cursor.execute(
            """INSERT INTO Instructor 
               (Ins_Id, Ins_FName, Ins_LName, Ins_Email, Password, Salary, Ins_Gender, Dep_Id) 
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (i, first_name, last_name, generate_email(first_name, last_name),
             f"Pass{random.randint(1000, 9999)}", random.randint(5000, 15000),
             gender, random.randint(1, len(departments)))
        )
        instructors.append({'Ins_Id': i, 'Ins_FName': first_name, 'Ins_LName': last_name})
    
    db.commit()
    print(f"   ✅ Inserted {len(instructors)} instructors")
    return instructors

def insert_instructor_phones(db: DatabaseConnection, instructors):
    """Insert Instructor_Phones data"""
    print("\n📱 Inserting Instructor Phones...")
    count = 0
    
    for inst in instructors:
        for _ in range(random.randint(1, 2)):
            db.cursor.execute(
                "INSERT INTO Instructor_Phones (Ins_Id, Phone) VALUES (?, ?)",
                (inst['Ins_Id'], generate_phone())
            )
            count += 1
    
    db.commit()
    print(f"   ✅ Inserted {count} phone numbers")

def insert_students(db: DatabaseConnection, departments, tracks, num_students=100):
    """Insert Student data"""
    print(f"\n👨‍🎓 Inserting {num_students} Students...")
    students = []
    
    for i in range(1, num_students + 1):
        gender = random.choice(['M', 'F'])
        first_name, last_name = get_random_name(gender)
        dept_id = random.randint(1, len(departments))
        
        db.cursor.execute(
            """INSERT INTO Student 
               (S_Id, S_FName, S_LName, S_Age, S_Email, S_GPA, Track_Id, Dep_Id) 
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (i, first_name, last_name, random.randint(18, 30),
             generate_email(first_name, last_name), round(random.uniform(2.0, 4.0), 2),
             random.randint(1, len(tracks)), dept_id)
        )
        students.append({'S_Id': i, 'S_FName': first_name, 'S_LName': last_name})
    
    db.commit()
    print(f"   ✅ Inserted {len(students)} students")
    return students

def insert_student_phones(db: DatabaseConnection, students):
    """Insert Student_Phones data"""
    print("\n📱 Inserting Student Phones...")
    count = 0
    
    for student in students:
        for _ in range(random.randint(1, 2)):
            db.cursor.execute(
                "INSERT INTO Student_Phones (S_Id, S_Phone) VALUES (?, ?)",
                (student['S_Id'], generate_phone())
            )
            count += 1
    
    db.commit()
    print(f"   ✅ Inserted {count} phone numbers")

def insert_courses(db: DatabaseConnection, tracks):
    """Insert Course data"""
    print("\n📚 Inserting Courses...")
    courses = []
    
    for i, course_name in enumerate(COURSES, 1):
        db.cursor.execute(
            """INSERT INTO Course (C_Id, C_Name, C_Des, C_Duration, Track_Id) 
               VALUES (?, ?, ?, ?, ?)""",
            (i, course_name, f"Comprehensive course in {course_name}",
             random.choice([30, 45, 60, 90]), random.randint(1, len(tracks)))
        )
        courses.append({'C_Id': i, 'C_Name': course_name})
    
    db.commit()
    print(f"   ✅ Inserted {len(courses)} courses")
    return courses

def insert_topics(db: DatabaseConnection):
    """Insert Topic data"""
    print("\n📖 Inserting Topics...")
    topics = []
    
    for i, topic_name in enumerate(TOPICS, 1):
        db.cursor.execute(
            "INSERT INTO Topic (Topic_Id, Topic_Name, Topic_Des) VALUES (?, ?, ?)",
            (i, topic_name, f"Study materials for {topic_name}")
        )
        topics.append({'Topic_Id': i, 'Topic_Name': topic_name})
    
    db.commit()
    print(f"   ✅ Inserted {len(topics)} topics")
    return topics

def insert_course_topics(db: DatabaseConnection, courses, topics):
    """Insert Course_Topic data"""
    print("\n🔗 Inserting Course-Topic mappings...")
    count = 0
    
    for course in courses:
        num_topics = random.randint(3, 5)
        selected_topics = random.sample(topics, min(num_topics, len(topics)))
        for topic in selected_topics:
            db.cursor.execute(
                "INSERT INTO Course_Topic (C_Id, Topic_Id) VALUES (?, ?)",
                (course['C_Id'], topic['Topic_Id'])
            )
            count += 1
    
    db.commit()
    print(f"   ✅ Inserted {count} course-topic mappings")

def insert_student_courses(db: DatabaseConnection, students, courses):
    """Insert Student_Course data"""
    print("\n📝 Inserting Student Course Enrollments...")
    enrollments = []
    
    for student in students:
        num_courses = random.randint(3, 6)
        selected_courses = random.sample(courses, min(num_courses, len(courses)))
        for course in selected_courses:
            enrollment_date = datetime.now() - timedelta(days=random.randint(1, 365))
            db.cursor.execute(
                "INSERT INTO Student_Course (S_Id, Course_Id, Enrollment_Date) VALUES (?, ?, ?)",
                (student['S_Id'], course['C_Id'], enrollment_date.strftime('%Y-%m-%d'))
            )
            enrollments.append({'S_Id': student['S_Id'], 'Course_Id': course['C_Id']})
    
    db.commit()
    print(f"   ✅ Inserted {len(enrollments)} enrollments")
    return enrollments

def insert_teaching(db: DatabaseConnection, enrollments, instructors):
    """Insert Teaching data"""
    print("\n👥 Inserting Teaching Assignments...")
    count = 0
    
    for enrollment in enrollments:
        instructor = random.choice(instructors)
        db.cursor.execute(
            "INSERT INTO Teaching (S_Id, Ins_Id, C_Id) VALUES (?, ?, ?)",
            (enrollment['S_Id'], instructor['Ins_Id'], enrollment['Course_Id'])
        )
        count += 1
    
    db.commit()
    print(f"   ✅ Inserted {count} teaching assignments")

def insert_exams(db: DatabaseConnection, courses):
    """Insert Exam data"""
    print("\n📝 Inserting Exams...")
    exams = []
    exam_id = 1
    
    for course in courses:
        for exam_num in range(random.randint(2, 3)):
            exam_date = datetime.now() - timedelta(days=random.randint(1, 365))
            db.cursor.execute(
                """INSERT INTO Exam (E_Id, E_Title, E_Total_Marks, E_Duaration, E_Date, C_Id) 
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (exam_id, f"{course['C_Name']} - Exam {exam_num + 1}",
                 random.choice([50, 75, 100]), random.choice([60, 90, 120]),
                 exam_date.strftime('%Y-%m-%d'), course['C_Id'])
            )
            exams.append({'E_Id': exam_id, 'C_Id': course['C_Id'], 'E_Date': exam_date.strftime('%Y-%m-%d')})
            exam_id += 1
    
    db.commit()
    print(f"   ✅ Inserted {len(exams)} exams")
    return exams

def insert_questions(db: DatabaseConnection, courses):
    """Insert Question data from real question bank"""
    print("\n❓ Inserting Real Questions...")
    questions = []
    question_id = 1
    
    for course in courses:
        course_name = course['C_Name']
        
        # Get questions for this course from question bank
        if course_name in QUESTION_BANK:
            course_questions = QUESTION_BANK[course_name]
            
            # Insert MCQ questions
            for mcq in course_questions.get('MCQ', []):
                db.cursor.execute(
                    """INSERT INTO Question (Q_Id, Q_Content, Q_Type, Q_Points, Q_hardness,C_ID) 
                       VALUES (?, ?, ?, ?, ?,?)""",
                    (question_id, mcq['q'], 'MCQ', mcq['points'], mcq['difficulty'],course['C_Id'])
                )
                questions.append({
                    'Q_Id': question_id, 
                    'Q_Type': 'MCQ',
                    'Q_Content': mcq['q'],
                    'choices': mcq['choices'],
                    'correct': mcq['correct']
                })
                question_id += 1
            
            # Insert True/False questions
            for tf in course_questions.get('TF', []):
                db.cursor.execute(
                    """INSERT INTO Question (Q_Id, Q_Content, Q_Type, Q_Points, Q_hardness,C_ID) 
                       VALUES (?, ?, ?, ?, ?,?)""",
                    (question_id, tf['q'], 'TF', tf['points'], tf['difficulty'],course['C_Id'])
                )
                questions.append({
                    'Q_Id': question_id, 
                    'Q_Type': 'TF',
                    'Q_Content': tf['q'],
                    'answer': tf['answer']
                })
                question_id += 1
        else:
            # Fallback for courses without specific questions
            for i in range(10):
                q_type = random.choice(['TF', 'MCQ'])
                db.cursor.execute(
                    """INSERT INTO Question (Q_Id, Q_Content, Q_Type, Q_Points, Q_hardness,C_ID) 
                       VALUES (?, ?, ?, ?, ?,?)""",
                    (question_id, f"General question about {course_name} - Q{i+1}",
                     q_type, random.choice([1, 2, 3]), random.choice(['Easy', 'Medium', 'Hard']),course['C_Id'])
                )
                questions.append({
                    'Q_Id': question_id, 
                    'Q_Type': q_type,
                    'Q_Content': f"General question about {course_name} - Q{i+1}"
                })
                question_id += 1
    
    db.commit()
    print(f"   ✅ Inserted {len(questions)} real questions")
    return questions

def insert_choices(db: DatabaseConnection, questions):
    """Insert Choice data with real answers"""
    print("\n✔️  Inserting Real Choices...")
    choices = []
    choice_id = 1
    
    for question in questions:
        if question['Q_Type'] == 'MCQ':
            # Check if we have real choices from question bank
            if 'choices' in question and 'correct' in question:
                # Use real choices from question bank
                for i, choice_text in enumerate(question['choices']):
                    is_correct = 1 if i == question['correct'] else 0
                    db.cursor.execute(
                        """INSERT INTO Choice (Choice_Id, Q_Id, Is_Correct, Choice_Content) 
                           VALUES (?, ?, ?, ?)""",
                        (choice_id, question['Q_Id'], is_correct, choice_text)
                    )
                    choices.append({'Choice_Id': choice_id, 'Q_Id': question['Q_Id']})
                    choice_id += 1
            else:
                # Fallback generic choices
                correct_choice = random.randint(0, 3)
                for i in range(4):
                    db.cursor.execute(
                        """INSERT INTO Choice (Choice_Id, Q_Id, Is_Correct, Choice_Content) 
                           VALUES (?, ?, ?, ?)""",
                        (choice_id, question['Q_Id'], 1 if i == correct_choice else 0,
                         f"Option {chr(65+i)}")
                    )
                    choices.append({'Choice_Id': choice_id, 'Q_Id': question['Q_Id']})
                    choice_id += 1
    
    db.commit()
    print(f"   ✅ Inserted {len(choices)} real answer choices")
    return choices

def insert_exam_questions(db: DatabaseConnection, exams, questions):
    """Insert Exam_Questions data - course-aligned"""
    print("\n🔗 Inserting Course-Aligned Exam-Question mappings...")
    count = 0
    
    for exam in exams:
        # Query questions for this specific course from the database
        db.cursor.execute(
            "SELECT Q_Id FROM Question WHERE C_ID = ?",
            (exam['C_Id'],)
        )
        course_question_ids = [row[0] for row in db.cursor.fetchall()]
        
        if not course_question_ids:
            print(f"   ⚠️  Warning: No questions found for exam {exam['E_Id']} (Course {exam['C_Id']})")
            continue
        
        # Select 5-10 questions from this course only
        num_questions = min(random.randint(5, 10), len(course_question_ids))
        selected_question_ids = random.sample(course_question_ids, num_questions)
        
        for question_id in selected_question_ids:
            db.cursor.execute(
                "INSERT INTO Exam_Questions (E_Id, Q_Id) VALUES (?, ?)",
                (exam['E_Id'], question_id)
            )
            count += 1
    
    db.commit()
    print(f"   ✅ Inserted {count} course-aligned exam-question mappings")


def insert_student_exams(db: DatabaseConnection, students, exams, enrollments):
    """Insert Student_Exam data"""
    print("\n📊 Inserting Student Exam Records...")
    student_exams = []
    
    for student in students[:50]:  # First 50 students
        student_courses = [e['Course_Id'] for e in enrollments if e['S_Id'] == student['S_Id']]
        available_exams = [e for e in exams if e['C_Id'] in student_courses]
        
        num_exams = min(random.randint(2, 5), len(available_exams))
        taken_exams = random.sample(available_exams, num_exams) if available_exams else []
        
        for exam in taken_exams:
            db.cursor.execute(
                "INSERT INTO Student_Exam (S_Id, E_Id, Grade, Date_Taken) VALUES (?, ?, ?, ?)",
                (student['S_Id'], exam['E_Id'], random.randint(50, 100), exam['E_Date'])
            )
            student_exams.append({'S_Id': student['S_Id'], 'E_Id': exam['E_Id']})
    
    db.commit()
    print(f"   ✅ Inserted {len(student_exams)} student exam records")
    return student_exams

def insert_student_answers(db: DatabaseConnection, student_exams, questions, choices):
    """Insert Student_Answer data"""
    print("\n✍️  Inserting Student Answers...")
    
    # Get exam questions mapping
    db.cursor.execute("SELECT E_Id, Q_Id FROM Exam_Questions")
    exam_questions = [{'E_Id': row[0], 'Q_Id': row[1]} for row in db.cursor.fetchall()]
    
    answer_id = 1
    count = 0
    
    for student_exam in student_exams:
        exam_qs = [eq for eq in exam_questions if eq['E_Id'] == student_exam['E_Id']]
        
        for eq in exam_qs:
            question = next((q for q in questions if q['Q_Id'] == eq['Q_Id']), None)
            if not question:
                continue
            
            choice_id_val = None
            if question['Q_Type'] == 'MCQ':
                q_choices = [c for c in choices if c['Q_Id'] == question['Q_Id']]
                if q_choices:
                    choice_id_val = random.choice(q_choices)['Choice_Id']
            
            db.cursor.execute(
                """INSERT INTO Student_Answer (A_Id, Question_Id, Exam_Id, Choice_Id, S_Id) 
                   VALUES (?, ?, ?, ?, ?)""",
                (answer_id, question['Q_Id'], student_exam['E_Id'], choice_id_val, student_exam['S_Id'])
            )
            answer_id += 1
            count += 1
    
    db.commit()
    print(f"   ✅ Inserted {count} student answers")

# ============================================================================
# MAIN FUNCTION
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description='Insert Egyptian mock data into ITI database')
    parser.add_argument('--server', default='localhost', help='SQL Server instance name')
    parser.add_argument('--database', default='ITI_E', help='Database name')
    parser.add_argument('--username', default='', help='Username (leave empty for Windows Auth)')
    parser.add_argument('--password', default='', help='Password')
    parser.add_argument('--students', type=int, default=100, help='Number of students to generate')
    parser.add_argument('--instructors', type=int, default=20, help='Number of instructors to generate')
    parser.add_argument('--clear', action='store_true', help='Clear existing data before insertion')
    parser.add_argument('--test-connection', action='store_true', help='Test connection only')
    
    args = parser.parse_args()
    
    # Build connection string
    if args.username:
        connection_string = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={args.server};"
            f"DATABASE={args.database};"
            f"UID={args.username};"
            f"PWD={args.password}"
        )
    else:
        connection_string = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={args.server};"
            f"DATABASE={args.database};"
            f"Trusted_Connection=yes;"
        )
    
    print("=" * 80)
    print("🇪🇬 ITI Egyptian Mock Data Insertion Script")
    print("=" * 80)
    print(f"\nServer: {args.server}")
    print(f"Database: {args.database}")
    print(f"Authentication: {'SQL Server' if args.username else 'Windows'}")
    
    # Create database connection
    db = DatabaseConnection(connection_string)
    
    if not db.connect():
        return
    
    if args.test_connection:
        print("\n✅ Connection test successful!")
        db.close()
        return
    
    try:
        # Disable foreign key constraints temporarily
        print("\n🔓 Temporarily disabling foreign key constraints...")
        db.cursor.execute("EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'")
        db.commit()
        
        # Clear existing data if requested
        if args.clear:
            clear_tables(db)
        
        # Insert data in proper foreign key order
        departments = insert_departments(db)
        tracks = insert_tracks(db, departments)
        insert_track_job_profiles(db, tracks)
        instructors = insert_instructors(db, departments, args.instructors)
        insert_instructor_phones(db, instructors)
        students = insert_students(db, departments, tracks, args.students)
        insert_student_phones(db, students)
        courses = insert_courses(db, tracks)
        topics = insert_topics(db)
        insert_course_topics(db, courses, topics)
        enrollments = insert_student_courses(db, students, courses)
        insert_teaching(db, enrollments, instructors)
        exams = insert_exams(db, courses)
        questions = insert_questions(db, courses)
        insert_exam_questions(db, exams, questions)
        student_exams = insert_student_exams(db, students, exams, enrollments)
        
        # Insert Student_Answer BEFORE Choice (due to FK_Choice_Student_Answer constraint)
        insert_student_answers(db, student_exams, questions, [])  # Pass empty choices list
        
        # Now insert Choice with actual data
        choices = insert_choices(db, questions)
        
        # Update Student_Answer with actual choice IDs
        print("\n🔄 Updating Student Answers with Choice IDs...")
        db.cursor.execute("SELECT E_Id, Q_Id FROM Exam_Questions")
        exam_questions = [{'E_Id': row[0], 'Q_Id': row[1]} for row in db.cursor.fetchall()]
        
        for student_exam in student_exams:
            exam_qs = [eq for eq in exam_questions if eq['E_Id'] == student_exam['E_Id']]
            for eq in exam_qs:
                question = next((q for q in questions if q['Q_Id'] == eq['Q_Id']), None)
                if question and question['Q_Type'] == 'MCQ':
                    q_choices = [c for c in choices if c['Q_Id'] == question['Q_Id']]
                    if q_choices:
                        choice_id_val = random.choice(q_choices)['Choice_Id']
                        db.cursor.execute(
                            "UPDATE Student_Answer SET Choice_Id = ? WHERE Question_Id = ? AND Exam_Id = ? AND S_Id = ?",
                            (choice_id_val, question['Q_Id'], student_exam['E_Id'], student_exam['S_Id'])
                        )
        db.commit()
        print("   ✅ Updated student answers with choice IDs")
        
        # Re-enable foreign key constraints
        print("\n🔒 Re-enabling foreign key constraints...")
        db.cursor.execute("EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL'")
        db.commit()
        
        
        print("\n" + "=" * 80)
        print("✅ ALL DATA INSERTED SUCCESSFULLY!")
        print("=" * 80)
        print("\n📊 Summary:")
        print(f"   • Departments: {len(departments)}")
        print(f"   • Tracks: {len(tracks)}")
        print(f"   • Instructors: {len(instructors)}")
        print(f"   • Students: {len(students)}")
        print(f"   • Courses: {len(courses)}")
        print(f"   • Topics: {len(topics)}")
        print(f"   • Exams: {len(exams)}")
        print(f"   • Questions: {len(questions)}")
        print(f"   • Choices: {len(choices)}")
        print(f"   • Student Exams: {len(student_exams)}")
        
    except Exception as e:
        print(f"\n❌ Error occurred: {e}")
        print("🔄 Rolling back transaction...")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    main()
