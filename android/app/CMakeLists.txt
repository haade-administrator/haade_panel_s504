cmake_minimum_required(VERSION 3.10.2)

project("mqtt_hatab")

# Déclare les bibliothèques natives importées (présentes dans jniLibs)
add_library(jnielc SHARED IMPORTED)
set_target_properties(jnielc PROPERTIES IMPORTED_LOCATION
    ${CMAKE_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libjnielc.so)

add_library(gpio_control SHARED IMPORTED)
set_target_properties(gpio_control PROPERTIES IMPORTED_LOCATION
    ${CMAKE_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libgpio_control.so)

# Si tu as un module natif à compiler (ex: native-lib.cpp), tu peux le déclarer ici :
# add_library(native-lib SHARED native-lib.cpp)

# Lier les bibliothèques importées à ton module natif (décommenter si tu as native-lib)
# target_link_libraries(native-lib jnielc gpio_control)

# Si tu n'as pas de code natif à compiler, cette partie est suffisante pour inclure les .so
