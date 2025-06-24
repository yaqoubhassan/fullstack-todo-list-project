import { useState } from "react";
import API_BASE_URL from "../utils/api.js";
import { CustomErrorAlert } from "../utils/general.js";

const useUpdateTodo = (setTodos) => {
  const [isLoading, setIsLoading] = useState(false);

  const updateTodo = async (todo) => {
    try {
      setIsLoading(true);
      const response = await fetch(`${API_BASE_URL}/todos/${todo._id}`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ isCompleted: !todo.isCompleted })
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      setTodos((prevTodos) =>
        prevTodos.map((item) =>
          item._id === todo._id
            ? { ...todo, isCompleted: !todo.isCompleted }
            : item
        )
      );
    } catch (error) {
      CustomErrorAlert(error.message);
    } finally {
      setIsLoading(false);
    }
  };

  return { updateTodo, isUpdatingTodo: isLoading };
};

export default useUpdateTodo;
