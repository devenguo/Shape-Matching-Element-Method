function g = SNH_dF(in1,Mu,La)
%SNH_DF
%    G = SNH_DF(IN1,MU,LA)

%    This function was generated by the Symbolic Math Toolbox version 8.5.
%    02-Apr-2021 04:12:06

%Version: 1.0
F1_1 = in1(1);
F1_2 = in1(4);
F1_3 = in1(7);
F2_1 = in1(2);
F2_2 = in1(5);
F2_3 = in1(8);
F3_1 = in1(3);
F3_2 = in1(6);
F3_3 = in1(9);
t2 = F1_1.^2;
t3 = F1_2.^2;
t4 = F1_3.^2;
t5 = F2_1.^2;
t6 = F2_2.^2;
t7 = F2_3.^2;
t8 = F3_1.^2;
t9 = F3_2.^2;
t10 = F3_3.^2;
t11 = F1_1.*F2_2.*F3_3;
t12 = F1_1.*F2_3.*F3_2;
t13 = F1_2.*F2_1.*F3_3;
t14 = F1_2.*F2_3.*F3_1;
t15 = F1_3.*F2_1.*F3_2;
t16 = F1_3.*F2_2.*F3_1;
t17 = 1.0./La;
t18 = -t11;
t19 = -t14;
t20 = -t15;
t21 = Mu.*t17.*(3.0./4.0);
t22 = t2+t3+t4+t5+t6+t7+t8+t9+t10+1.0;
t23 = 1.0./t22;
t24 = t12+t13+t16+t18+t19+t20+t21+1.0;
g = [F1_1.*Mu.*2.0-La.*t24.*(F2_2.*F3_3-F2_3.*F3_2).*2.0-F1_1.*Mu.*t23.*2.0;F2_1.*Mu.*2.0+La.*t24.*(F1_2.*F3_3-F1_3.*F3_2).*2.0-F2_1.*Mu.*t23.*2.0;F3_1.*Mu.*2.0-La.*t24.*(F1_2.*F2_3-F1_3.*F2_2).*2.0-F3_1.*Mu.*t23.*2.0;F1_2.*Mu.*2.0+La.*t24.*(F2_1.*F3_3-F2_3.*F3_1).*2.0-F1_2.*Mu.*t23.*2.0;F2_2.*Mu.*2.0-La.*t24.*(F1_1.*F3_3-F1_3.*F3_1).*2.0-F2_2.*Mu.*t23.*2.0;F3_2.*Mu.*2.0+La.*t24.*(F1_1.*F2_3-F1_3.*F2_1).*2.0-F3_2.*Mu.*t23.*2.0;F1_3.*Mu.*2.0-La.*t24.*(F2_1.*F3_2-F2_2.*F3_1).*2.0-F1_3.*Mu.*t23.*2.0;F2_3.*Mu.*2.0+La.*t24.*(F1_1.*F3_2-F1_2.*F3_1).*2.0-F2_3.*Mu.*t23.*2.0;F3_3.*Mu.*2.0-La.*t24.*(F1_1.*F2_2-F1_2.*F2_1).*2.0-F3_3.*Mu.*t23.*2.0];
