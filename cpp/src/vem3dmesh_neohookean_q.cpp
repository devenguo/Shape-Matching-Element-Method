#ifdef SIM_STATIC_LIBRARY
# include<../include/vem3dmesh_neohookean_q.h>
#endif

#ifdef VEM_USE_OPENMP
#include <omp.h>
#endif

template<typename DerivedC, typename DerivedVol, typename DerivedParam>
double sim::vem3dmesh_neohookean_q(const Eigen::VectorXx<DerivedC> &c,
	const Eigen::VectorXx<DerivedVol> &volume,
	const Eigen::MatrixXx<DerivedParam> &params,
	const std::vector<Eigen::MatrixXd, Eigen::aligned_allocator<Eigen::MatrixXd> > & dF_dc,
	const std::vector<Eigen::SparseMatrix<double>, Eigen::aligned_allocator<Eigen::SparseMatrix<double>> > & dF_dc_S,
	int d) {

	double energy = 0;

	// TODO move this to separate file
	for (int i = 0; i < dF_dc.size(); ++i) {
		Eigen::MatrixXx<DerivedParam> CD = params.row(i);

		// std::cout << "CD = " << CD << std::endl;
		// std::cout << "dF_dc[i] = " << dF_dc[i] << std::endl;
		// std::cout << "dF_dc_S[i] = " << dF_dc_S[i] << std::endl;

		Eigen::MatrixXd F_flat = dF_dc[i] * dF_dc_S[i] * c;
		// std::cout << "F_flat = " << F_flat << std::endl;

		Eigen::Matrix3d F = unflatten<3, 3>(F_flat);

		// std::cout << "F = " << F << std::endl;
		// std::cout << "volume(i) = " << volume(i) << std::endl;
		// std::cout << "psi = " << psi_neohookean_F(F, params) << std::endl;

		energy += psi_neohookean_F(F, params) *  volume(i);
	}
	
	// std::cout << "c = " << c << std::endl;
	// std::cout << "energy = " << energy << std::endl;

	return energy;
}

#include <iostream>