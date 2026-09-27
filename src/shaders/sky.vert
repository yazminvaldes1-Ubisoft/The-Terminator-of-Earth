#include "renderer.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <png.h>

static char *read_file_to_string(const char *path) {
    FILE *file = fopen(path, "rb");
    if (!file) {
        return NULL;
    }

    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);

    if (length <= 0) {
        fclose(file);
        return NULL;
    }

    char *buffer = (char *)malloc((size_t)length + 1);
    if (!buffer) {
        fclose(file);
        return NULL;
    }

    size_t read_count = fread(buffer, 1, (size_t)length, file);
    buffer[read_count] = '\0';
    fclose(file);
    return buffer;
}

static GLuint compile_shader(GLenum type, const char *source) {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);

    GLint status = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        char log[2048];
        glGetShaderInfoLog(shader, sizeof(log), NULL, log);
        fprintf(stderr, "Shader compile error: %s\n", log);
        glDeleteShader(shader);
        return 0;
    }

    return shader;
}

static GLuint create_program(const char *vertex_path, const char *fragment_path) {
    char *vertex_source = read_file_to_string(vertex_path);
    char *fragment_source = read_file_to_string(fragment_path);
    if (!vertex_source || !fragment_source) {
        fprintf(stderr, "Failed to read shader source files: %s and %s\n", vertex_path, fragment_path);
        free(vertex_source);
        free(fragment_source);
        return 0;
    }

    GLuint vertex_shader = compile_shader(GL_VERTEX_SHADER, vertex_source);
    GLuint fragment_shader = compile_shader(GL_FRAGMENT_SHADER, fragment_source);
    free(vertex_source);
    free(fragment_source);

    if (!vertex_shader || !fragment_shader) {
        return 0;
    }

    GLuint program = glCreateProgram();
    glAttachShader(program, vertex_shader);
    glAttachShader(program, fragment_shader);
    glLinkProgram(program);

    GLint status = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        char log[2048];
        glGetProgramInfoLog(program, sizeof(log), NULL, log);
        fprintf(stderr, "Program link error: %s\n", log);
        glDeleteProgram(program);
        glDeleteShader(vertex_shader);
        glDeleteShader(fragment_shader);
        return 0;
    }

    glDeleteShader(vertex_shader);
    glDeleteShader(fragment_shader);
    return program;
}

static void generate_fallback_texture(GLuint *texture_id, int width, int height) {
    unsigned char *pixels = (unsigned char *)malloc((size_t)width * height * 4);
    if (!pixels) {
        return;
    }

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            int index = (y * width + x) * 4;
            float t = (float)y / (float)(height - 1);

            unsigned char r = (unsigned char)(50 + (int)(200.0f * (1.0f - t)));
            unsigned char g = (unsigned char)(90 + (int)(160.0f * (1.0f - t)));
            unsigned char b = (unsigned char)(180 + (int)(75.0f * (1.0f - t)));

            pixels[index + 0] = r;
            pixels[index + 1] = g;
            pixels[index + 2] = b;
            pixels[index + 3] = 255;
        }
    }

    glGenTextures(1, texture_id);
    glBindTexture(GL_TEXTURE_2D, *texture_id);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    free(pixels);
}

static int load_png_texture(const char *path, GLuint *texture_id, int *out_width, int *out_height) {
    FILE *fp = fopen(path, "rb");
    if (!fp) {
        return 0;
    }

    png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (!png_ptr) {
        fclose(fp);
        return 0;
    }

    png_infop info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr) {
        png_destroy_read_struct(&png_ptr, NULL, NULL);
        fclose(fp);
        return 0;
    }

    if (setjmp(png_jmpbuf(png_ptr))) {
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        fclose(fp);
        return 0;
    }

    png_init_io(png_ptr, fp);
    png_read_info(png_ptr, info_ptr);

    png_uint_32 width = png_get_image_width(png_ptr, info_ptr);
    png_uint_32 height = png_get_image_height(png_ptr, info_ptr);
    png_uint_32 bit_depth = png_get_bit_depth(png_ptr, info_ptr);
    png_uint_32 color_type = png_get_color_type(png_ptr, info_ptr);

    if (bit_depth == 16) {
        png_set_strip_16(png_ptr);
    }
    if (color_type == PNG_COLOR_TYPE_PALETTE) {
        png_set_palette_to_rgb(png_ptr);
    }
    if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) {
        png_set_expand_gray_1_2_4_to_8(png_ptr);
    }
    if (png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS)) {
        png_set_tRNS_to_alpha(png_ptr);
    }
    if (color_type == PNG_COLOR_TYPE_RGB || color_type == PNG_COLOR_TYPE_GRAY || color_type == PNG_COLOR_TYPE_PALETTE) {
        png_set_add_alpha(png_ptr, 255, PNG_FILLER_AFTER);
    }

    png_read_update_info(png_ptr, info_ptr);

    png_size_t rowbytes = png_get_rowbytes(png_ptr, info_ptr);
    png_bytep *row_pointers = (png_bytep *)malloc(sizeof(png_bytep) * height);
    if (!row_pointers) {
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        fclose(fp);
        return 0;
    }

    unsigned char *image_data = (unsigned char *)malloc(rowbytes * height);
    if (!image_data) {
        free(row_pointers);
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        fclose(fp);
        return 0;
    }

    for (png_uint_32 y = 0; y < height; ++y) {
        row_pointers[y] = image_data + (size_t)y * rowbytes;
    }

    png_read_image(png_ptr, row_pointers);
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(fp);

    glGenTextures(1, texture_id);
    glBindTexture(GL_TEXTURE_2D, *texture_id);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image_data);
    glGenerateMipmap(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    free(row_pointers);
    free(image_data);

    *out_width = (int)width;
    *out_height = (int)height;
    return 1;
}

int renderer_init(Renderer *renderer, const char *sky_texture_path) {
    glClearColor(0.1f, 0.1f, 0.15f, 1.0f);

    renderer->shader_program = create_program("src/shaders/sky.vert", "src/shaders/sky.frag");
    if (!renderer->shader_program) {
        fprintf(stderr, "Failed to create sky shader program\n");
        return 0;
    }

    GLfloat quad_vertices[] = {
        -1.0f, -1.0f, 0.0f,
         1.0f, -1.0f, 0.0f,
         1.0f,  1.0f, 0.0f,
        -1.0f,  1.0f, 0.0f,
    };

    glGenVertexArrays(1, &renderer->vao);
    glBindVertexArray(renderer->vao);

    GLuint vbo = 0;
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quad_vertices), quad_vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void *)0);
    glEnableVertexAttribArray(0);

    if (sky_texture_path && load_png_texture(sky_texture_path, &renderer->texture_id, &renderer->width, &renderer->height)) {
        fprintf(stdout, "Loaded sky texture: %s (%d x %d)\n", sky_texture_path, renderer->width, renderer->height);
    } else {
        generate_fallback_texture(&renderer->texture_id, 1024, 512);
        renderer->width = 1024;
        renderer->height = 512;
        fprintf(stdout, "Using fallback sky texture. Add assets/sky_day.png to use your custom HDRI-style sky.\n");
    }

    return 1;
}

void renderer_draw(Renderer *renderer, const glm::mat4 &view, const glm::mat4 &projection) {
    glUseProgram(renderer->shader_program);

    glm::mat4 inv_view_proj = glm::inverse(projection * view);
    GLint inv_view_proj_loc = glGetUniformLocation(renderer->shader_program, "uInvViewProj");
    GLint sky_tex_loc = glGetUniformLocation(renderer->shader_program, "uSkyTexture");

    glUniformMatrix4fv(inv_view_proj_loc, 1, GL_FALSE, glm::value_ptr(inv_view_proj));

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, renderer->texture_id);
    glUniform1i(sky_tex_loc, 0);

    glDisable(GL_DEPTH_TEST);
    glBindVertexArray(renderer->vao);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glEnable(GL_DEPTH_TEST);
}

void renderer_destroy(Renderer *renderer) {
    if (renderer->shader_program) {
        glDeleteProgram(renderer->shader_program);
    }
    if (renderer->vao) {
        glDeleteVertexArrays(1, &renderer->vao);
    }
    if (renderer->texture_id) {
        glDeleteTextures(1, &renderer->texture_id);
    }
}
