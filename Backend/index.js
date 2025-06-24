import express from "express";
import cors from "cors";
import mongoose from "mongoose";

const app = express();
const PORT = process.env.PORT || 3000;

// CORS Configuration
const corsOptions = {
  origin: process.env.CORS_ORIGIN || [
    "http://localhost:3000",
    "http://localhost:80",
    "http://localhost:5173"
  ],
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"]
};

// Middleware
app.use(cors(corsOptions));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Database Connection
const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://localhost:27017/todos";

mongoose
  .connect(MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
  })
  .then(() => {
    console.log(`Connected to MongoDB at: ${MONGODB_URI}`);
  })
  .catch((err) => {
    console.error("MongoDB connection error:", err.message);
    process.exit(1);
  });

// Mongoose Schema and Models
const todoSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
      minlength: 1,
      maxlength: 200
    },
    date: {
      type: String,
      default: () => new Date().toISOString().split("T")[0]
    },
    activity: {
      type: String,
      trim: true,
      maxlength: 100
    },
    description: {
      type: String,
      required: true,
      trim: true,
      minlength: 1,
      maxlength: 1000
    },
    strStatus: {
      type: String,
      enum: ["pending", "in-progress", "completed"],
      default: "pending"
    },
    isCompleted: {
      type: Boolean,
      default: false
    }
  },
  {
    timestamps: true
  }
);

const Todos = mongoose.model("Todos", todoSchema);

// Health check endpoint
app.get("/", (req, res) => {
  res.status(200).json({
    message: "Todo API is running!",
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || "development"
  });
});

// Get all todos with pagination
app.get("/api/gettodos", async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const totalCount = await Todos.countDocuments();
    const todoList = await Todos.find()
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const numOfPages = Math.ceil(totalCount / limit);

    res.status(200).json({
      todoList,
      numOfPages,
      currentPage: page,
      totalItems: totalCount
    });
  } catch (error) {
    console.error("Error fetching todos:", error);
    res.status(500).json({
      message: "Internal server error"
    });
  }
});

// Create new todo
app.post("/api/todos", async (req, res) => {
  try {
    const { title, description, activity, date, strStatus } = req.body;

    if (!title || title.trim().length === 0) {
      return res.status(400).json({ message: "Title is required" });
    }
    if (!description || description.trim().length === 0) {
      return res.status(400).json({ message: "Description is required" });
    }

    const todo = new Todos({
      title: title.trim(),
      description: description.trim(),
      activity: activity?.trim(),
      date: date || new Date().toISOString().split("T")[0],
      strStatus: strStatus || "pending"
    });

    await todo.save();

    res.status(201).json({
      message: "Todo created successfully",
      todo
    });
  } catch (error) {
    console.error("Error creating todo:", error);
    res.status(500).json({
      message: "Internal server error"
    });
  }
});

// Update todo
app.put("/api/todos/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: "Invalid todo ID" });
    }

    const todo = await Todos.findByIdAndUpdate(
      id,
      { ...updates, updatedAt: new Date() },
      { new: true, runValidators: true }
    );

    if (!todo) {
      return res.status(404).json({ message: "Todo not found" });
    }

    res.status(200).json({
      message: "Todo updated successfully",
      todo
    });
  } catch (error) {
    console.error("Error updating todo:", error);
    res.status(500).json({
      message: "Internal server error"
    });
  }
});

// Delete todo
app.delete("/api/todos/:id", async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: "Invalid todo ID" });
    }

    const todo = await Todos.findByIdAndDelete(id);

    if (!todo) {
      return res.status(404).json({ message: "Todo not found" });
    }

    res.status(200).json({
      message: "Todo deleted successfully"
    });
  } catch (error) {
    console.error("Error deleting todo:", error);
    res.status(500).json({
      message: "Internal server error"
    });
  }
});

// Start the server
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server is running on http://0.0.0.0:${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
});
