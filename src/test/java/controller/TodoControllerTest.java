package controller;

import controller.TodoController;
import model.TodoRequest;
import model.TodoResponse;
import service.TodoService;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.ResponseEntity;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

public class TodoControllerTest {

    private TodoService todoService;
    private TodoController todoController;

    @BeforeEach
    void setUp() {
        todoService = mock(TodoService.class);
        todoController = new TodoController(todoService);
    }

    @Test
    void testCreateTodo() {
        TodoRequest request = new TodoRequest();
        request.setTitle("Test Title");
        request.setDescription("Test Description");

        TodoResponse response = new TodoResponse();
        response.setTitle("Test Title");
        response.setDescription("Test Description");

        when(todoService.createTodo(request)).thenReturn(response);

        ResponseEntity<TodoResponse> result = todoController.createTodo(request);

        assertEquals(200, result.getStatusCodeValue());
        assertEquals("Test Title", result.getBody().getTitle());
        assertEquals("Test Description", result.getBody().getDescription());

        verify(todoService, times(1)).createTodo(request);
    }

    @Test
    void testGetTodoById() {
        String todoId = "123";
        TodoResponse todo = new TodoResponse();
        todo.setId(todoId);
        todo.setTitle("Sample Todo");

        when(todoService.getTodoById(todoId)).thenReturn(todo);

        ResponseEntity<TodoResponse> response = todoController.getTodo(todoId);

        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals("123", response.getBody().getId());
        assertEquals("Sample Todo", response.getBody().getTitle());

        verify(todoService, times(1)).getTodoById(todoId);
    }

    @Test
    void testDeleteTodo() {
        String todoId = "123";

        doNothing().when(todoService).deleteTodo(todoId);

        ResponseEntity<Void> response = todoController.deleteTodo(todoId);

        assertEquals(204, response.getStatusCodeValue());
        verify(todoService, times(1)).deleteTodo(todoId);
    }
}