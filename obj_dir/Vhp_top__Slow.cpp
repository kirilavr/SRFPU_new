// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vhp_top.h for the primary calling header

#include "Vhp_top.h"
#include "Vhp_top__Syms.h"

//==========

VL_CTOR_IMP(Vhp_top) {
    Vhp_top__Syms* __restrict vlSymsp = __VlSymsp = new Vhp_top__Syms(this, name());
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Reset internal values
    
    // Reset structure values
    _ctor_var_reset();
}

void Vhp_top::__Vconfigure(Vhp_top__Syms* vlSymsp, bool first) {
    if (false && first) {}  // Prevent unused
    this->__VlSymsp = vlSymsp;
    if (false && this->__VlSymsp) {}  // Prevent unused
    Verilated::timeunit(-12);
    Verilated::timeprecision(-12);
}

Vhp_top::~Vhp_top() {
    VL_DO_CLEAR(delete __VlSymsp, __VlSymsp = NULL);
}

void Vhp_top::_eval_initial(Vhp_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhp_top::_eval_initial\n"); );
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void Vhp_top::final() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhp_top::final\n"); );
    // Variables
    Vhp_top__Syms* __restrict vlSymsp = this->__VlSymsp;
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void Vhp_top::_eval_settle(Vhp_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhp_top::_eval_settle\n"); );
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_combo__TOP__1(vlSymsp);
    vlTOPp->__Vm_traceActivity[1U] = 1U;
    vlTOPp->__Vm_traceActivity[0U] = 1U;
}

void Vhp_top::_ctor_var_reset() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhp_top::_ctor_var_reset\n"); );
    // Body
    src_a = VL_RAND_RESET_I(16);
    src_b = VL_RAND_RESET_I(16);
    operation = VL_RAND_RESET_I(3);
    ops_ready = VL_RAND_RESET_I(1);
    res_out = VL_RAND_RESET_I(16);
    zero = VL_RAND_RESET_I(1);
    inf = VL_RAND_RESET_I(1);
    subN = VL_RAND_RESET_I(1);
    Norm = VL_RAND_RESET_I(1);
    QNan = VL_RAND_RESET_I(1);
    SNan = VL_RAND_RESET_I(1);
    hp_top__DOT__a_zero = VL_RAND_RESET_I(1);
    hp_top__DOT__a_inf = VL_RAND_RESET_I(1);
    hp_top__DOT__a_subN = VL_RAND_RESET_I(1);
    hp_top__DOT__a_QNan = VL_RAND_RESET_I(1);
    hp_top__DOT__a_SNan = VL_RAND_RESET_I(1);
    hp_top__DOT__b_zero = VL_RAND_RESET_I(1);
    hp_top__DOT__b_inf = VL_RAND_RESET_I(1);
    hp_top__DOT__b_subN = VL_RAND_RESET_I(1);
    hp_top__DOT__b_QNan = VL_RAND_RESET_I(1);
    hp_top__DOT__b_SNan = VL_RAND_RESET_I(1);
    hp_top__DOT__mul_res_zero = VL_RAND_RESET_I(1);
    hp_top__DOT__mul_res_inf = VL_RAND_RESET_I(1);
    hp_top__DOT__mul_res_subN = VL_RAND_RESET_I(1);
    hp_top__DOT__mul_res_Norm = VL_RAND_RESET_I(1);
    hp_top__DOT__mul_res_QNan = VL_RAND_RESET_I(1);
    hp_top__DOT__mul_res_SNan = VL_RAND_RESET_I(1);
    hp_top__DOT__rounding_reg = VL_RAND_RESET_I(22);
    hp_top__DOT__trunc_result = VL_RAND_RESET_I(16);
    hp_top__DOT__multiplier__DOT__a_exp = VL_RAND_RESET_I(6);
    hp_top__DOT__multiplier__DOT__b_exp = VL_RAND_RESET_I(6);
    hp_top__DOT__multiplier__DOT__a_mant = VL_RAND_RESET_I(11);
    hp_top__DOT__multiplier__DOT__b_mant = VL_RAND_RESET_I(11);
    hp_top__DOT__multiplier__DOT__res_exp = VL_RAND_RESET_I(6);
    hp_top__DOT__multiplier__DOT__res_mant = VL_RAND_RESET_I(22);
    hp_top__DOT__multiplier__DOT__clz_rin = VL_RAND_RESET_I(10);
    hp_top__DOT__multiplier__DOT__clz_rout = VL_RAND_RESET_I(4);
    hp_top__DOT__multiplier__DOT__clz__DOT__rin = VL_RAND_RESET_I(10);
    { int __Vi0=0; for (; __Vi0<2; ++__Vi0) {
            __Vm_traceActivity[__Vi0] = VL_RAND_RESET_I(1);
    }}
}
