// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract TodoList {
    struct Todo {
        string text;
        bool completed;
    }

    Todo[] public todos;

    function create(string calldata text) external {
        todos.push(Todo(text, false));
    }

    function updateText(uint index, string calldata newText) external {
        Todo storage todo = todos[index];
        todo.text = newText;
    }

    function get(uint index) external view returns (string memory, bool) {
        Todo storage todo = todos[index];
        return (todo.text, todo.completed);
    }

    function toggleCompleted(uint index) external {
        Todo storage todo = todos[index];
        todo.completed = !todo.completed;
    }
}
