import { useState } from "react";
import API_BASE_URL from "../utils/api.js";
import { CustomErrorAlert } from "../utils/general.js";

const useDeleteTodo = (fetchTodos, page, limit) => {
  const [isLoading, setIsLoading] = useState(false);
  let status = false;

  const deleteTodo = async (id) => {
    try {
      setIsLoading(true);
      const response = await fetch(`${API_BASE_URL}/todos/${id}`, {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json"
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      status = response.ok;
      await fetchTodos(page, limit);
    } catch (error) {
      CustomErrorAlert(error.message);
    } finally {
      setIsLoading(false);
    }
    return status;
  };

  return { deleteTodo, isDeletingTodo: isLoading };
};

export default useDeleteTodo;
