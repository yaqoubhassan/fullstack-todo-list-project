import { useState } from "react";
import API_BASE_URL from "../utils/api.js";
import { CustomErrorAlert } from "../utils/general.js";

const useGetTodos = (setTodos, setNumOfPages, setPage) => {
  const [isLoading, setIsLoading] = useState(true);

  const fetchTodos = async (page, limit) => {
    setIsLoading(true);
    try {
      const response = await fetch(
        `${API_BASE_URL}/gettodos?page=${page}&limit=${limit}`
      );
      const data = await response.json();
      setTodos(data.todoList || []);
      setNumOfPages(data.numOfPages || 1);
      if (page > data.numOfPages) setPage(data.numOfPages);
    } catch (error) {
      CustomErrorAlert(error.message);
    } finally {
      setIsLoading(false);
    }
  };

  return { fetchTodos, isFetchingTodos: isLoading };
};

export default useGetTodos;
