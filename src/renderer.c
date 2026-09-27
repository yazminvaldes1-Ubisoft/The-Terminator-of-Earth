#pragma once

#include <GL/glew.h>
#include <glm/glm.hpp>
#include <glm/gtc/type_ptr.hpp>

typedef struct {
    GLuint shader_program;
    GLuint vao;
    GLuint texture_id;
    int width;
    int height;
} Renderer;

int renderer_init(Renderer *renderer, const char *sky_texture_path);
void renderer_draw(Renderer *renderer, const glm::mat4 &view, const glm::mat4 &projection);
void renderer_destroy(Renderer *renderer);
