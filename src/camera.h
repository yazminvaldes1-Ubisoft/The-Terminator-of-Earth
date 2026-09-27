#pragma once

#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#define CAMERA_SPEED 5.0f
#define CAMERA_SENSITIVITY 0.0025f

typedef struct {
    glm::vec3 position;
    float yaw;
    float pitch;
    glm::mat4 view;
    glm::mat4 projection;
} Camera;

void camera_init(Camera *camera, const glm::vec3 position);
void camera_update_view(Camera *camera);
void camera_set_projection(Camera *camera, float fov_degrees, float aspect_ratio, float near_plane, float far_plane);
void camera_handle_input(Camera *camera, GLFWwindow *window, float delta_time);
