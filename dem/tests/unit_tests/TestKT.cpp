// @HEADER
// **********************************************************************************************************************
//
//      AG2025 : Software supporting Alsous et al. The physical consequences of sperm gigantism, Nat. Phys. 2025
//                               Copyright 2025 Flatiron Institute | Author Bryce Palmer
//
// AG2025 is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
// AG2025 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
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
#include <openrand/philox.h>

// C++ core
#include <stdexcept>  // for logic_error, invalid_argument, etc

// Mundy
#include <mundy_core/throw_assert.hpp>  // for MUNDY_THROW_ASSERT
#include <mundy_math/Matrix3.hpp>     // for mundy::math::Matrix3
#include <mundy_math/Quaternion.hpp>  // for mundy::math::Quaternion, mundy::math::quat_from_parallel_transport
#include <mundy_math/Vector3.hpp>     // for mundy::math::Vector3
#include <mundy_geom/randomize.hpp>

//! \name An auxilary test to check that our K and K^T matrix-free implementations are indeed transposes of each other
//@{

namespace mundy {

namespace {

struct Dependencies {
  double node_radius;

  math::Vector3d edge_im1_tangent;
  math::Vector3d edge_i_tangent;

  math::Vector3d edge_im1_binormal;
  math::Vector3d edge_i_binormal;

  double edge_im1_length;
  double edge_i_length;

  math::Quaterniond edge_im1_orientation;
  math::Quaterniond edge_i_orientation;
};

math::Vector<double, 11> apply_KT(const math::Vector3d &node_torque_i, const Dependencies &d) {
  auto node_i_rotation_grad = math::conjugate(d.edge_im1_orientation) * d.edge_i_orientation;

  // We'll reuse the bending torque for the rotated bending torque
  auto lab_node_torque_i = d.edge_im1_orientation * (node_i_rotation_grad.w() * node_torque_i +
                                                     math::cross(node_i_rotation_grad.vector(), node_torque_i));

  // Compute the force and torque on the nodes
  const double proj_torque_i = math::dot(lab_node_torque_i, d.edge_i_tangent);
  const double proj_torque_im1 = math::dot(lab_node_torque_i, d.edge_im1_tangent);
  const double proj_binormal_i = math::dot(d.edge_i_binormal, d.edge_i_tangent);
  const double proj_binormal_im1 = math::dot(d.edge_im1_binormal, d.edge_im1_tangent);

  const auto tmp_ip1 = math::cross(lab_node_torque_i, d.edge_i_tangent) - 0.5 * proj_torque_i * d.edge_i_binormal;
  const auto tmp_im1 = math::cross(lab_node_torque_i, d.edge_im1_tangent) - 0.5 * proj_torque_im1 * d.edge_im1_binormal;
  const auto force_ip1 = 1.0 / d.edge_i_length * (tmp_ip1 - math::dot(tmp_ip1, d.edge_i_tangent) * d.edge_i_tangent);
  const auto force_im1 =
      1.0 / d.edge_im1_length * (tmp_im1 - math::dot(tmp_im1, d.edge_im1_tangent) * d.edge_im1_tangent);

  // const auto force_ip1 = 1.0 / d.edge_i_length *
  //                             (math::cross(lab_node_torque_i, d.edge_i_tangent)
  //                             -0.5 * proj_torque_i * d.edge_i_binormal
  //                             +0.5 * proj_binormal_i * proj_torque_i * d.edge_i_tangent);
  // const auto force_im1 = 1.0 / d.edge_im1_length *
  //                             (math::cross(lab_node_torque_i, d.edge_im1_tangent)
  //                             -0.5 * proj_torque_im1 * d.edge_im1_binormal
  //                             +0.5 * proj_binormal_im1 * proj_torque_im1 * d.edge_im1_tangent);
  const auto force_i = -force_ip1 - force_im1;
  const auto twist_torque_i = proj_torque_i;
  const auto twist_torque_im1 = -proj_torque_im1;

  // Stash the result in a single vector
  math::Vector<double, 11> result;
  result[0] = force_im1[0];
  result[1] = force_im1[1];
  result[2] = force_im1[2];
  result[3] = force_i[0];
  result[4] = force_i[1];
  result[5] = force_i[2];
  result[6] = force_ip1[0];
  result[7] = force_ip1[1];
  result[8] = force_ip1[2];
  result[9] = twist_torque_im1;
  result[10] = twist_torque_i;
  return result;
}

math::Vector3d apply_K(const math::Vector<double, 11> input, const Dependencies &d) {
  // Unpack the input into vel_im1, vel_i, twist_vel_im1, twist_vel_i
  math::Vector3d vel_im1{input[0], input[1], input[2]};
  math::Vector3d vel_i{input[3], input[4], input[5]};
  math::Vector3d vel_ip1{input[6], input[7], input[8]};
  double twist_vel_im1 = input[9];
  double twist_vel_i = input[10];

  auto node_i_rotation_grad = math::conjugate(d.edge_im1_orientation) * d.edge_i_orientation;

  auto vel_diff_ip1 = vel_ip1 - vel_i;
  auto projected_vel_diff_i =
      (vel_diff_ip1 - math::dot(vel_diff_ip1, d.edge_i_tangent) * d.edge_i_tangent) / d.edge_i_length;
  auto binormal_stuff_i = math::cross(d.edge_i_tangent, projected_vel_diff_i) -
                          0.5 * d.edge_i_tangent * math::dot(projected_vel_diff_i, d.edge_i_binormal);

  auto vel_diff_i = vel_i - vel_im1;
  auto projected_vel_diff_im1 =
      (vel_diff_i - math::dot(vel_diff_i, d.edge_im1_tangent) * d.edge_im1_tangent) / d.edge_im1_length;
  auto binormal_stuff_im1 = math::cross(d.edge_im1_tangent, projected_vel_diff_im1) -
                            0.5 * d.edge_im1_tangent * math::dot(projected_vel_diff_im1, d.edge_im1_binormal);

  auto tmp1 =
      d.edge_i_tangent * twist_vel_i - d.edge_im1_tangent * twist_vel_im1 + binormal_stuff_i - binormal_stuff_im1;
  auto tmp2 = math::conjugate(d.edge_im1_orientation) * tmp1;

  math::Vector3d rate_of_change_of_curvature_i =
      node_i_rotation_grad.w() * tmp2 - math::cross(node_i_rotation_grad.vector(), tmp2);
  return rate_of_change_of_curvature_i;
}

double run_is_transpose_test(size_t seed) {
  math::Matrix<double, 3, 11> K(0);   // 3 rows and 11 columns
  math::Matrix<double, 11, 3> KT(0);  // 11 rows and 3 columns

  // Randomize the dependencies
  openrand::Philox rng(seed, 0);
  Dependencies d;
  d.node_radius = rng.rand<double>() + 0.1;

  auto old_tangent_im1 = geom::generate_random_unit_vector<double>(rng);
  auto old_tangent_i = geom::generate_random_unit_vector<double>(rng);

  d.edge_im1_length = rng.rand<double>() + 0.1;
  d.edge_i_length = rng.rand<double>() + 0.1;
  d.edge_im1_orientation = geom::generate_random_unit_quaternion<double>(rng);
  d.edge_i_orientation = geom::generate_random_unit_quaternion<double>(rng);
  d.edge_im1_tangent = d.edge_im1_orientation * math::Vector3d(0.0, 0.0, 1.0);
  d.edge_i_tangent = d.edge_i_orientation * math::Vector3d(0.0, 0.0, 1.0);
  d.edge_im1_binormal =
      (2 * math::cross(old_tangent_im1, d.edge_im1_tangent)) / (1.0 + math::dot(old_tangent_im1, d.edge_im1_tangent));
  d.edge_i_binormal =
      (2 * math::cross(old_tangent_i, d.edge_i_tangent)) / (1.0 + math::dot(old_tangent_i, d.edge_i_tangent));

  // Fill KT
  for (unsigned col = 0; col < 3; ++col) {
    math::Vector<double, 3> e_i(0);
    e_i[col] = 1.0;
    auto KT_col = apply_KT(e_i, d);
    KT.set_column(col, KT_col);
  }

  // Fill K
  for (unsigned col = 0; col < 11; ++col) {
    math::Vector<double, 11> e_i(0);
    e_i[col] = 1.0;
    auto K_col = apply_K(e_i, d);
    K.set_column(col, K_col);
  }

  double res = math::two_norm(KT - math::transpose(K));
  return res;
}

TEST(BendingElasticity, IsTranspose) {
  // Out goal in this test is to demonstrate that out K^T matrix is actually the the transpose of the K matrix.
  // We never actually construct the matrices so we will do this via acting on on the columns of the identity matrix
  // to extract K and K^T.

  size_t num_trials = 10000;
  for (size_t i = 0; i < num_trials; ++i) {
    double res_i = run_is_transpose_test(i);
    ASSERT_LT(res_i, 1e-12) << "K and KT are not their transpose up to a residual of 1e-12!";
  }
}

}  // namespace

} // namespace mundy
