cmake_minimum_required(VERSION 3.16)
project(TheTerminatorOfEarth LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

find_package(OpenGL REQUIRED)
find_package(glfw3 REQUIRED)
find_package(GLEW REQUIRED)
find_package(PNG REQUIRED)
find_package(glm REQUIRED)

add_executable(the_terminator_of_earth
    src/main.c
    src/camera.c
    src/camera.h
    src/renderer.c
    src/renderer.h
)

target_include_directories(the_terminator_of_earth PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(the_terminator_of_earth PRIVATE
    glfw
    GLEW::GLEW
    OpenGL::GL
    PNG::PNG
)

if(TARGET glm::glm)
    target_link_libraries(the_terminator_of_earth PRIVATE glm::glm)
else()
    target_include_directories(the_terminator_of_earth PRIVATE ${GLM_INCLUDE_DIRS})
endif()

file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/src/shaders" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
