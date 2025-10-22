// @HEADER
// **********************************************************************************************************************
//
//                                          Sam: A Starter Application Using Mundy
//                                             Copyright 2025 Bryce Palmer
//
// Sam is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
// Sam is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
// of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with Mundy. If not, see
// <https://www.gnu.org/licenses/>.
//
// **********************************************************************************************************************
// @HEADER

//! \file GTestMain.cpp
/// \brief Main function for all GoogleTest-driven tests within this library
///
/// Simply link this file with the test files you want to run. GTest will automatically find all the tests in the
/// linked files and run them.

// External
#include <gmock/gmock.h>  // for EXPECT_THAT, HasSubstr, etc
#include <gtest/gtest.h>  // for TEST, ASSERT_NO_THROW, etc
#include <mpi.h>       // for MPI_Comm, MPI_Finalize, etc

// Trilinos
#include <Kokkos_Core.hpp>  // for Kokkos::initialize, Kokkos::finalize

int main(int argc, char** argv) {
  // Initialize MPI and Kokkos
  MPI_Init(&argc, &argv);
  Kokkos::initialize(argc, argv);

  testing::InitGoogleMock(&argc, argv);
  int return_val = RUN_ALL_TESTS();

  Kokkos::finalize();
  MPI_Finalize();

  return return_val;
}