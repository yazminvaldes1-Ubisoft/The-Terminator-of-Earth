#include "camera.h"

void camera_init(Camera *camera, const glm::vec3 position) {
    camera->position = position;
    camera->yaw = -90.0f;
    camera->pitch = 0.0f;
    camera->view = glm::mat4(1.0f);
    camera->projection = glm::mat4(1.0f);
    camera_update_view(camera);
}

void camera_update_view(Camera *camera) {
    glm::vec3 direction;
    direction.x = cos(glm::radians(camera->yaw)) * cos(glm::radians(camera->pitch));
    direction.y = sin(glm::radians(camera->pitch));
    direction.z = sin(glm::radians(camera->yaw)) * cos(glm::radians(camera->pitch));

    glm::vec3 front = glm::normalize(direction);
    glm::vec3 up(0.0f, 1.0f, 0.0f);
    camera->view = glm::lookAt(camera->position, camera->position + front, up);
}

void camera_set_projection(Camera *camera, float fov_degrees, float aspect_ratio, float near_plane, float far_plane) {
    camera->projection = glm::perspective(glm::radians(fov_degrees), aspect_ratio, near_plane, far_plane);
}

void camera_handle_input(Camera *camera, GLFWwindow *window, float delta_time) {
    float speed = CAMERA_SPEED * delta_time;

    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS) {
        camera->position += glm::normalize(glm::vec3(
            cos(glm::radians(camera->yaw)) * cos(glm::radians(camera->pitch)),
            sin(glm::radians(camera->pitch)),
            sin(glm::radians(camera->yaw)) * cos(glm::radians(camera->pitch))
        )) * speed;
    }

    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS) {
        camera->position -= glm::normalize(glm::vec3(
            cos(glm::radians(camera->yaw)) * cos(glm::radians(camera->pitch)),
            sin(glm::radians(camera->pitch)),
            sin(glm::radians(camera->yaw)) * cos(glm::radians(camera->pitch))
        )) * speed;
    }

    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS) {
        glm::vec3 forward = glm::normalize(glm::vec3(
            cos(glm::radians(camera->yaw)) * cos(glm::radians(camera->pitch)),
            0.0f,
            sin(glm::radians(camera->yaw)) * cos(glm::radians(camera->pitch))
        ));
        glm::vec3 right = glm::normalize(glm::cross(forward, glm::vec3(0.0f, 1.0f, 0.0f)));
        camera->position -= right * speed;
    }

    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS) {
        glm::vec3 forward = glm::normalize(glm::vec3(
            cos(glm::radians(camera->yaw)) * cos(glm::radians(camera->pitch)),
            0.0f,
            sin(glm::radians(camera->yaw)) * cos(glm::radians(camera->pitch))
        ));
        glm::vec3 right = glm::normalize(glm::cross(forward, glm::vec3(0.0f, 1.0f, 0.0f)));
        camera->position += right * speed;
    }

    if (glfwGetKey(window, GLFW_KEY_SPACE) == GLFW_PRESS) {
        camera->position.y += speed;
    }

    if (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS) {
        camera->position.y -= speed;
    }

    double mouse_x, mouse_y;
    glfwGetCursorPos(window, &mouse_x, &mouse_y);

    static double last_x = 0.0;
    static double last_y = 0.0;
    static bool first_mouse = true;

    if (first_mouse) {
        last_x = mouse_x;
        last_y = mouse_y;
        first_mouse = false;
    }

    double dx = mouse_x - last_x;
    double dy = mouse_y - last_y;
    last_x = mouse_x;
    last_y = mouse_y;

    camera->yaw += float(dx) * CAMERA_SENSITIVITY * 100.0f;
    camera->pitch -= float(dy) * CAMERA_SENSITIVITY * 100.0f;

    if (camera->pitch > 89.0f) camera->pitch = 89.0f;
    if (camera->pitch < -89.0f) camera->pitch = -89.0f;

    camera_update_view(camera);
}
