# Sam – A Starter Application Using Mundy

## Welcome and Purpose

Sam is a mock **C++** application built on the *Mundy* framework, which we use as the template for all of our formal Mundy applications. If all you desire is to use Mundy within your library, simply use `find_package(Mundy)` and `target_link_libraries(some_exe Private Mundy::all_libs)`. But if you desire to build a formal application that depends on Mundy, this template helps streamline that process. We assume basic C++ knowledge (e.g. you've taken an introductory course) and introductory level **CMake** knowledge, with most things CMake-related handled for you or explained in full detail.

The purpose of "Sam" is to provide a standardized, working setup for our various applications. It includes a straightforward `main` program, a testing setup, and the necessary CMake configuration to work with the Mundy framework. By exploring this template, you'll learn how to structure a CMake-based project, manage source files, write unit tests, and build/install everything in a way that meets formal standards.

---
## Quick Start

To build and run Sam:
```bash
mkdir build && cd build
cmake .. -DMundy_DIR=~/local/ -DCMAKE_INSTALL_PREFIX=~/local/
make -j12
```

This produces two executables:
- `Sam.X` – your main program
- `Sam_unit_tests.X` – your GoogleTest-based test suite

Run them directly from the `build/` directory:
```bash
./Sam.X
./Sam_unit_tests.X
```

To install the Sam library after building:
```bash
make install
```

---
## Customize the Template

Follow these steps to customize the template for your own project:

1. **Set your project name** – Open the `ProjectName.cmake` file and change the project name from "Sam" to your desired name. Use PascalCase for consistency (e.g., MyProject).
2. **Update file headers** – Update file headers and license mentions to reflect your project name and author.
3. **Review the license** – (Optional) By default, this template (and Mundy itself) is licensed under **GNU GPLv3**, which is a *copyleft* license. If you have a preferred non-GPLv3 copyleft license, feel free to swap to it instead. For details, see the **License Guidance** section.

## License Guidance

**Why GPLv3?** Mundy is released under the GNU General Public License v3.0, a strong *copyleft* license that ensures distributed versions of your software remain open, collaborative, and not quietly re-sold by others. Any project that links against GPLv3 libraries must use a GPLv3-compatible license (such as the Apache Software License, version 2.0). Importantly, MIT and BDS are not-compatible. If you’re unsure about licenses, keep the default — it’s compliant and beginner-safe.

---
## Source Structure and Main Function

All your application code lives in the **`src/`** directory. Here's a quick overview of the repository structure (simplified):

```plaintext
mundy_mock_app/
├── src/               # Your application source code
│   ├── main.cpp       # Entry point (contains int main())
│   └── ...            # Other source (.cpp) and header (.h) files you add
├── tests/             # Unit tests (see next section)
│   ├── GTestMain.cpp  # Test runner main() for GoogleTest
│   ├── unit_tests/    # Directory for test case files
|       └── TestUnitTests.cpp  # Example unit test
│       └── ...           
├── CMakeLists.txt     # Top-level CMake build script
├── ProjectName.cmake  # Project name definition (included by CMakeLists)
├── cmake/SamConfig.cmake.in   # Template for CMake package configuration (advanced)
└── LICENSE            # License file (GPLv3)
```

The most important parts for now are the `src/` directory and the CMake build scripts. The `src/main.cpp` file is the **entry point** of the application – this is where the `int main()` function is defined. By default,  it prints a greeting and demonstrates basic Mundy integration.

You can add your own **.cpp** and **.hpp** files into the `src/` folder as you develop your project. For example, you might create `src/Helper.hpp` and `src/Helper.cpp` for a new class or module. The build system will need to know about these new files. In CMake, you usually list source files for the executable target via `target_sources`. 

Open `src/CMakeLists.txt` (the CMake script inside the src directory): you'll see that it defines the sources for the `Sam` executable. To add new source files, simply append them to the `target_sources` list:

```cmake
# Add new source files to the executable target
target_sources(${PROJECT_NAME} PRIVATE 
    Helper.cpp
    AnotherModule.cpp
)
```

*(Note: You don't need to list header files in `target_sources` — only the .cpp implementation files.)*

If you prefer to organize code into subfolders under `src/`, that's fine too. Just remember that if you create a new subdirectory, add a `CMakeLists.txt` to it with the necessary `target_sources` and add a corresponding `add_subdirectory()` call in the parent CMakeLists.txt.

---
## Unit Testing

This template comes with a basic **unit testing** setup using **Google Test** (a popular C++ testing framework). All test-related code is in the **`tests/`** directory. The important parts are:

- `tests/GTestMain.cpp` – This file contains a `main()` function that initializes Google Test and runs all the tests. It uses `::testing::InitGoogleTest()` and `RUN_ALL_TESTS()`. Because this main function is provided, **you do not need to write a `main()` in any of your test files**.
- `tests/unit_tests/TestUnitTests.cpp` – This is an example test source file. It demonstrates how to write test cases using the Google Test macros. For instance, you'll see something like:
  ```cpp
  TEST(SampleTest, AdditionWorks) {
      EXPECT_EQ(2 + 2, 4);   // A simple test checking that 2+2 equals 4
  }
  ```
- `tests/unit_tests/` (directory) – You can put additional test files in this folder (or create new subfolders if you prefer). 

To add a new test file to the build, list it in the CMake configuration for tests. The unit test executable target is typically named after your project with `_unit_tests.X` appended (for "Sam" it becomes **`Sam_unit_tests.X`**). In the CMake scripts, this name is stored in a variable (e.g. `utest_ex_name`). To include a new test source, open the appropriate CMakeLists (check `tests/CMakeLists.txt` or `tests/unit_tests/CMakeLists.txt` in the template) and use `target_sources` for the test target. For example, if you created a new test file `MyFeatureTest.cpp` under `tests/unit_tests/`, you would add:

```cmake
target_sources(${utest_ex_name} PRIVATE
    MyFeatureTest.cpp
)
```

By default, building the project will also build the test executable. To disable test building, pass `-DSam_ENABLE_UNIT_TESTS=OFF` when running CMake.

---
**Installing (optional):** Installing isn't required to run or develop the code, but it's useful if you want to use Sam as a component elsewhere or deploy it system-wide. Running `make install` in the build directory will copy `Sam.X` (and any other deliverables) to the install directory (e.g., under `~/local/` in `bin/` and related folders) and install the CMake package files for Sam. We provide all of the formal cmake configurations to ensure that downstream CMake project can then find and link Sam via `find_package(Sam)` and `target_link_libraries(some_exe Private Sam::Sam)`.

---
## Understanding CMakeLists.txt

If you're new to CMake, the build scripts might look a bit complex at first (to be honest, even if you aren't new to CMake, it's a little dense). Don't worry – you don't need to be a CMake expert to use this template. Likely, all you'll need to do is make small tweaks here to there, like adding a new dependency via `find_package` and `target_link_libraries`. We demonstrate this by adding MPI as a dependency. 
