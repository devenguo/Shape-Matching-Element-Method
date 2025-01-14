#ifdef SIM_STATIC_LIBRARY
# include<../include/vem3dmesh_neohookean_dq.h>
#endif

#ifdef VEM_USE_OPENMP
#include <omp.h>
#endif

template<typename DerivedRet, typename DerivedX, typename DerivedC, typename DerivedVol, typename DerivedParam>
void sim::vem3dmesh_neohookean_dq(Eigen::VectorXx<DerivedRet> &g,
	const Eigen::MatrixXx<DerivedX> &x,
	const Eigen::VectorXx<DerivedC> &c,
	const Eigen::VectorXx<DerivedVol> &volume,
	const Eigen::MatrixXx<DerivedParam> &params,
	const std::vector<Eigen::MatrixXd, Eigen::aligned_allocator<Eigen::MatrixXd> > & dF_dc,
	const std::vector<Eigen::SparseMatrix<double>, Eigen::aligned_allocator<Eigen::SparseMatrix<double>> > & dF_dc_S,
	const Eigen::MatrixXd &ME,
	const Eigen::SparseMatrix<double> &L,
	int k, int n, int d, int x0_coms_size, double k_stability) {

	Eigen::VectorXd dV_dq, dV_dF;
	dV_dq.resize(d*(k*n + x0_coms_size));
	dV_dq.setZero();
	dV_dF.resize(9);

	for (int i = 0; i < dF_dc.size(); ++i) {
		Eigen::MatrixXx<DerivedParam> CD = params.row(i);
		Eigen::VectorXd F_flat = dF_dc[i] * dF_dc_S[i] * c;
		Eigen::Matrix3d F = unflatten<3, 3>(F_flat);

		dpsi_neohookean_dF(dV_dF, F, CD);

		// std::cout << "dV_dF[" << i << "] = " << dV_dF.transpose() << std::endl;
		
		dV_dq += dF_dc_S[i].transpose() * dF_dc[i].transpose() * dV_dF * volume(i);

		// if (i < 2) {
		// 		std::cout << "i = " << i << std::endl;
		// 		std::cout << "F = " << std::endl << F << std::endl;
		// 		std::cout << "CD = " << std::endl << CD << std::endl;
		// 		std::cout << "dV_dF = " << std::endl << dV_dF << std::endl;
		// 		std::cout << "dV_dq = " << std::endl <<  dV_dq.segment(0,10) << std::endl;
		// }
		
	}

	// std::cout << "total dV_dq = " << dV_dq.segment(0,10) << std::endl;

	dV_dq = L.transpose() * dV_dq;

	// std::cout << "dV_dq with L= " << dV_dq.segment(0,9) << std::endl;

	//  Error correction force
	Eigen::VectorXd x_vec = Eigen::Map<const Eigen::VectorXd>(x.data(), x.size());
	Eigen::MatrixXd f_error_tmp = - 2.0 * ME * x_vec;
	Eigen::VectorXd f_error_tmp_vec = Eigen::Map<Eigen::VectorXd>(f_error_tmp.data(), f_error_tmp.size());
	Eigen::VectorXd f_error = -k_stability * f_error_tmp_vec;

	// std::cout << "x_vec = " << x_vec << std::endl;
	// std::cout << "f_error_tmp = " << f_error_tmp << std::endl;
	// std::cout << "f_error_tmp_vec = " << f_error_tmp_vec << std::endl;
	// std::cout << "f_error = " << f_error.segment(0,9) << std::endl;

  // Force from potential energy.
	Eigen::VectorXd f_internal = dV_dq;

	g = f_internal + f_error;

	// std::cout << "g = " << g.segment(0,10) << std::endl;
}

#include <iostream>