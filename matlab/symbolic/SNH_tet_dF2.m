function H = SNH_tet_dF2(in1,C,D)
%SNH_TET_DF2
%    H = SNH_TET_DF2(IN1,C,D)

%    This function was generated by the Symbolic Math Toolbox version 8.5.
%    18-Nov-2020 21:19:31

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
t2 = C.*2.0;
t3 = C.*F1_1;
t4 = C.*F1_2;
t5 = C.*F1_3;
t6 = C.*F2_1;
t7 = C.*F2_2;
t8 = C.*F2_3;
t9 = C.*F3_1;
t10 = C.*F3_2;
t11 = C.*F3_3;
t12 = F1_1.*F2_2;
t13 = F1_2.*F2_1;
t14 = F1_1.*F2_3;
t15 = F1_3.*F2_1;
t16 = F1_2.*F2_3;
t17 = F1_3.*F2_2;
t18 = F1_1.*F3_2;
t19 = F1_2.*F3_1;
t20 = F1_1.*F3_3;
t21 = F1_3.*F3_1;
t22 = F1_2.*F3_3;
t23 = F1_3.*F3_2;
t24 = F2_1.*F3_2;
t25 = F2_2.*F3_1;
t26 = F2_1.*F3_3;
t27 = F2_3.*F3_1;
t28 = F2_2.*F3_3;
t29 = F2_3.*F3_2;
t30 = F3_3.*t12;
t31 = F3_2.*t14;
t32 = F3_3.*t13;
t33 = F3_1.*t16;
t34 = F3_2.*t15;
t35 = F3_1.*t17;
t36 = -t3;
t37 = -t4;
t38 = -t5;
t39 = -t6;
t40 = -t7;
t41 = -t8;
t42 = -t9;
t43 = -t10;
t44 = -t11;
t45 = -t13;
t46 = -t15;
t47 = -t17;
t48 = -t19;
t49 = -t21;
t50 = -t23;
t51 = -t25;
t52 = -t27;
t53 = -t29;
t54 = -t30;
t55 = -t33;
t56 = -t34;
t57 = t12+t45;
t58 = t14+t46;
t59 = t16+t47;
t60 = t18+t48;
t61 = t20+t49;
t62 = t22+t50;
t63 = t24+t51;
t64 = t26+t52;
t65 = t28+t53;
t66 = D.*t57.*t58.*2.0;
t67 = D.*t57.*t59.*2.0;
t68 = D.*t58.*t59.*2.0;
t69 = D.*t57.*t60.*2.0;
t70 = D.*t57.*t61.*2.0;
t71 = D.*t58.*t60.*2.0;
t72 = D.*t57.*t62.*2.0;
t73 = D.*t58.*t61.*2.0;
t74 = D.*t59.*t60.*2.0;
t75 = D.*t58.*t62.*2.0;
t76 = D.*t59.*t61.*2.0;
t77 = D.*t59.*t62.*2.0;
t78 = D.*t57.*t63.*2.0;
t79 = D.*t57.*t64.*2.0;
t80 = D.*t58.*t63.*2.0;
t81 = D.*t60.*t61.*2.0;
t82 = D.*t57.*t65.*2.0;
t83 = D.*t58.*t64.*2.0;
t84 = D.*t59.*t63.*2.0;
t85 = D.*t60.*t62.*2.0;
t86 = D.*t58.*t65.*2.0;
t87 = D.*t59.*t64.*2.0;
t88 = D.*t61.*t62.*2.0;
t89 = D.*t59.*t65.*2.0;
t90 = D.*t60.*t63.*2.0;
t91 = D.*t60.*t64.*2.0;
t92 = D.*t61.*t63.*2.0;
t93 = D.*t60.*t65.*2.0;
t94 = D.*t61.*t64.*2.0;
t95 = D.*t62.*t63.*2.0;
t96 = D.*t61.*t65.*2.0;
t97 = D.*t62.*t64.*2.0;
t98 = D.*t62.*t65.*2.0;
t99 = D.*t63.*t64.*2.0;
t100 = D.*t63.*t65.*2.0;
t101 = D.*t64.*t65.*2.0;
t122 = t31+t32+t35+t54+t55+t56+1.0;
t102 = -t66;
t103 = -t68;
t104 = -t69;
t105 = -t72;
t106 = -t73;
t107 = -t74;
t108 = -t77;
t109 = -t79;
t110 = -t80;
t111 = -t81;
t112 = -t86;
t113 = -t87;
t114 = -t88;
t115 = -t90;
t116 = -t93;
t117 = -t94;
t118 = -t95;
t119 = -t98;
t120 = -t99;
t121 = -t101;
t123 = D.*F1_1.*t122.*2.0;
t124 = D.*F1_2.*t122.*2.0;
t125 = D.*F1_3.*t122.*2.0;
t126 = D.*F2_1.*t122.*2.0;
t127 = D.*F2_2.*t122.*2.0;
t128 = D.*F2_3.*t122.*2.0;
t129 = D.*F3_1.*t122.*2.0;
t130 = D.*F3_2.*t122.*2.0;
t131 = D.*F3_3.*t122.*2.0;
t132 = -t123;
t133 = -t124;
t134 = -t125;
t135 = -t126;
t136 = -t127;
t137 = -t128;
t138 = -t129;
t139 = -t130;
t140 = -t131;
t141 = t3+t71+t123;
t142 = t5+t76+t125;
t143 = t7+t84+t127;
t144 = t9+t92+t129;
t145 = t11+t97+t131;
t146 = t4+t105+t124;
t147 = t6+t109+t126;
t148 = t8+t112+t128;
t149 = t10+t116+t130;
t150 = t36+t70+t132;
t151 = t38+t75+t134;
t152 = t40+t82+t136;
t153 = t42+t91+t138;
t154 = t44+t96+t140;
t155 = t37+t107+t133;
t156 = t39+t110+t135;
t157 = t41+t113+t137;
t158 = t43+t118+t139;
H = reshape([t2+D.*t65.^2.*2.0,t119,t89,t121,t154,t148,t100,t149,t152,t119,t2+D.*t62.^2.*2.0,t108,t145,t114,t151,t158,t85,t146,t89,t108,t2+D.*t59.^2.*2.0,t157,t142,t103,t143,t155,t67,t121,t145,t157,t2+D.*t64.^2.*2.0,t117,t83,t120,t153,t147,t154,t114,t142,t117,t2+D.*t61.^2.*2.0,t106,t144,t111,t150,t148,t151,t103,t83,t106,t2+D.*t58.^2.*2.0,t156,t141,t102,t100,t158,t143,t120,t144,t156,t2+D.*t63.^2.*2.0,t115,t78,t149,t85,t155,t153,t111,t141,t115,t2+D.*t60.^2.*2.0,t104,t152,t146,t67,t147,t150,t102,t78,t104,t2+D.*t57.^2.*2.0],[9,9]);