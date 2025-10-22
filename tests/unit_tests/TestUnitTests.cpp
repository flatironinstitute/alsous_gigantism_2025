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

// External
#include <gmock/gmock.h>  // for EXPECT_THAT, HasSubstr, etc
#include <gtest/gtest.h>  // for TEST, ASSERT_NO_THROW, etc

// C++ core
#include <stdexcept>  // for logic_error, invalid_argument, etc

// Mundy
#include <mundy_core/throw_assert.hpp>  // for MUNDY_THROW_ASSERT

TEST(ExampleTest, UseMundyThrowRequire) {
  // This test will pass if the MUNDY_THROW_REQUIRE macro is working correctly, confirming that
  // we have linked mundy correctly and that our tests are set up properly.
  EXPECT_THROW(MUNDY_THROW_REQUIRE(false, std::logic_error, "Throwing error"),
               std::logic_error);
}
