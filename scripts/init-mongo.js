// Switch to the todos database
db = db.getSiblingDB("todos");

// Create a user for the application
db.createUser({
  user: "todoapp",
  pwd: "todopass123",
  roles: [
    {
      role: "readWrite",
      db: "todos"
    }
  ]
});

// Create collections with validation
db.createCollection("todos", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["title", "description"],
      properties: {
        title: {
          bsonType: "string",
          description: "Title must be a string and is required"
        },
        description: {
          bsonType: "string",
          description: "Description must be a string and is required"
        },
        isCompleted: {
          bsonType: "bool",
          description: "isCompleted must be a boolean"
        },
        activity: {
          bsonType: "string",
          description: "Activity must be a string"
        },
        date: {
          bsonType: "string",
          description: "Date must be a string"
        },
        strStatus: {
          bsonType: "string",
          description: "Status must be a string"
        }
      }
    }
  }
});

// Create indexes for better performance
db.todos.createIndex({ "title": 1 });
db.todos.createIndex({ "isCompleted": 1 });
db.todos.createIndex({ "createdAt": 1 });

// Insert some sample data
db.todos.insertMany([
  {
    title: "Welcome to Todo App",
    description:
      "This is your first todo item. You can mark it as complete or delete it.",
    isCompleted: false,
    activity: "Getting Started",
    date: new Date().toISOString().split("T")[0],
    strStatus: "pending",
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    title: "Explore the Features",
    description:
      "Try adding new todos, marking them complete, and managing your tasks efficiently.",
    isCompleted: false,
    activity: "Exploration",
    date: new Date().toISOString().split("T")[0],
    strStatus: "pending",
    createdAt: new Date(),
    updatedAt: new Date()
  }
]);

print("Database initialized successfully!");
