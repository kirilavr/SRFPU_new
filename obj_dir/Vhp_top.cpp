// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vhp_top.h for the primary calling header

#include "Vhp_top.h"
#include "Vhp_top__Syms.h"

//==========

void Vhp_top::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vhp_top::eval\n"); );
    Vhp_top__Syms* __restrict vlSymsp = this->__VlSymsp;  // Setup global symbol table
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
#ifdef VL_DEBUG
    // Debug assertions
    _eval_debug_assertions();
#endif  // VL_DEBUG
    // Initialize
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) _eval_initial_loop(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Clock loop\n"););
        vlSymsp->__Vm_activity = true;
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("rtl/hp_top.sv", 25, "",
                "Verilated model didn't converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

void Vhp_top::_eval_initial_loop(Vhp_top__Syms* __restrict vlSymsp) {
    vlSymsp->__Vm_didInit = true;
    _eval_initial(vlSymsp);
    vlSymsp->__Vm_activity = true;
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        _eval_settle(vlSymsp);
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("rtl/hp_top.sv", 25, "",
                "Verilated model didn't DC converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

VL_INLINE_OPT void Vhp_top::_combo__TOP__1(Vhp_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhp_top::_combo__TOP__1\n"); );
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->hp_top__DOT__multiplier__DOT__a_exp = (0x3fU 
                                                   & ((0x1fU 
                                                       & ((IData)(vlTOPp->src_a) 
                                                          >> 0xaU)) 
                                                      - (IData)(0xfU)));
    vlTOPp->hp_top__DOT__multiplier__DOT__b_exp = (0x3fU 
                                                   & ((0x1fU 
                                                       & ((IData)(vlTOPp->src_b) 
                                                          >> 0xaU)) 
                                                      - (IData)(0xfU)));
    vlTOPp->hp_top__DOT__a_subN = ((~ (IData)((0U != 
                                               (0x1fU 
                                                & ((IData)(vlTOPp->src_a) 
                                                   >> 0xaU))))) 
                                   & (0U != (0x3ffU 
                                             & (IData)(vlTOPp->src_a))));
    vlTOPp->hp_top__DOT__b_subN = ((~ (IData)((0U != 
                                               (0x1fU 
                                                & ((IData)(vlTOPp->src_b) 
                                                   >> 0xaU))))) 
                                   & (0U != (0x3ffU 
                                             & (IData)(vlTOPp->src_b))));
    vlTOPp->hp_top__DOT__a_QNan = ((0x1fU == (0x1fU 
                                              & ((IData)(vlTOPp->src_a) 
                                                 >> 0xaU))) 
                                   & ((IData)(vlTOPp->src_a) 
                                      >> 9U));
    vlTOPp->hp_top__DOT__a_inf = ((0x1fU == (0x1fU 
                                             & ((IData)(vlTOPp->src_a) 
                                                >> 0xaU))) 
                                  & (~ (IData)((0U 
                                                != 
                                                (0x3ffU 
                                                 & (IData)(vlTOPp->src_a))))));
    vlTOPp->hp_top__DOT__a_zero = (1U & ((~ (IData)(
                                                    (0U 
                                                     != 
                                                     (0x1fU 
                                                      & ((IData)(vlTOPp->src_a) 
                                                         >> 0xaU))))) 
                                         & (~ (IData)(
                                                      (0U 
                                                       != 
                                                       (0x3ffU 
                                                        & (IData)(vlTOPp->src_a)))))));
    vlTOPp->hp_top__DOT__b_QNan = ((0x1fU == (0x1fU 
                                              & ((IData)(vlTOPp->src_b) 
                                                 >> 0xaU))) 
                                   & ((IData)(vlTOPp->src_b) 
                                      >> 9U));
    vlTOPp->hp_top__DOT__b_inf = ((0x1fU == (0x1fU 
                                             & ((IData)(vlTOPp->src_b) 
                                                >> 0xaU))) 
                                  & (~ (IData)((0U 
                                                != 
                                                (0x3ffU 
                                                 & (IData)(vlTOPp->src_b))))));
    vlTOPp->hp_top__DOT__b_zero = (1U & ((~ (IData)(
                                                    (0U 
                                                     != 
                                                     (0x1fU 
                                                      & ((IData)(vlTOPp->src_b) 
                                                         >> 0xaU))))) 
                                         & (~ (IData)(
                                                      (0U 
                                                       != 
                                                       (0x3ffU 
                                                        & (IData)(vlTOPp->src_b)))))));
    vlTOPp->hp_top__DOT__a_SNan = (((0x1fU == (0x1fU 
                                               & ((IData)(vlTOPp->src_a) 
                                                  >> 0xaU))) 
                                    & (~ ((IData)(vlTOPp->src_a) 
                                          >> 9U))) 
                                   & (0U != (0x3ffU 
                                             & (IData)(vlTOPp->src_a))));
    vlTOPp->hp_top__DOT__b_SNan = (((0x1fU == (0x1fU 
                                               & ((IData)(vlTOPp->src_b) 
                                                  >> 0xaU))) 
                                    & (~ ((IData)(vlTOPp->src_b) 
                                          >> 9U))) 
                                   & (0U != (0x3ffU 
                                             & (IData)(vlTOPp->src_b))));
    if (((IData)(vlTOPp->hp_top__DOT__a_SNan) | (IData)(vlTOPp->hp_top__DOT__b_SNan))) {
        vlTOPp->hp_top__DOT__mul_res_SNan = 1U;
    }
    if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_SNan) 
                  | (IData)(vlTOPp->hp_top__DOT__b_SNan))))) {
        if (((IData)(vlTOPp->hp_top__DOT__a_QNan) | (IData)(vlTOPp->hp_top__DOT__b_QNan))) {
            vlTOPp->hp_top__DOT__mul_res_QNan = 1U;
        } else {
            if (((IData)(vlTOPp->hp_top__DOT__a_inf) 
                 | (IData)(vlTOPp->hp_top__DOT__b_inf))) {
                if (((IData)(vlTOPp->hp_top__DOT__a_zero) 
                     | (IData)(vlTOPp->hp_top__DOT__b_zero))) {
                    vlTOPp->hp_top__DOT__mul_res_QNan = 1U;
                }
            }
        }
    }
    if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_SNan) 
                  | (IData)(vlTOPp->hp_top__DOT__b_SNan))))) {
        if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_QNan) 
                      | (IData)(vlTOPp->hp_top__DOT__b_QNan))))) {
            if (((IData)(vlTOPp->hp_top__DOT__a_inf) 
                 | (IData)(vlTOPp->hp_top__DOT__b_inf))) {
                if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_zero) 
                              | (IData)(vlTOPp->hp_top__DOT__b_zero))))) {
                    vlTOPp->hp_top__DOT__mul_res_inf = 1U;
                }
            }
        }
    }
    if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_SNan) 
                  | (IData)(vlTOPp->hp_top__DOT__b_SNan))))) {
        if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_QNan) 
                      | (IData)(vlTOPp->hp_top__DOT__b_QNan))))) {
            if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_inf) 
                          | (IData)(vlTOPp->hp_top__DOT__b_inf))))) {
                if ((((IData)(vlTOPp->hp_top__DOT__a_zero) 
                      | (IData)(vlTOPp->hp_top__DOT__b_zero)) 
                     | ((IData)(vlTOPp->hp_top__DOT__a_subN) 
                        & (IData)(vlTOPp->hp_top__DOT__b_subN)))) {
                    vlTOPp->hp_top__DOT__mul_res_zero = 1U;
                }
            }
        }
    }
    vlTOPp->hp_top__DOT__mul_res_zero = 1U;
    vlTOPp->hp_top__DOT__trunc_result = 0U;
    if (((IData)(vlTOPp->hp_top__DOT__a_SNan) | (IData)(vlTOPp->hp_top__DOT__b_SNan))) {
        vlTOPp->hp_top__DOT__trunc_result = ((IData)(vlTOPp->hp_top__DOT__a_SNan)
                                              ? (IData)(vlTOPp->src_a)
                                              : (IData)(vlTOPp->src_b));
    } else {
        if (((IData)(vlTOPp->hp_top__DOT__a_QNan) | (IData)(vlTOPp->hp_top__DOT__b_QNan))) {
            vlTOPp->hp_top__DOT__trunc_result = ((IData)(vlTOPp->hp_top__DOT__a_QNan)
                                                  ? (IData)(vlTOPp->src_a)
                                                  : (IData)(vlTOPp->src_b));
        } else {
            if (((IData)(vlTOPp->hp_top__DOT__a_inf) 
                 | (IData)(vlTOPp->hp_top__DOT__b_inf))) {
                vlTOPp->hp_top__DOT__trunc_result = 
                    (((IData)(vlTOPp->hp_top__DOT__a_zero) 
                      | (IData)(vlTOPp->hp_top__DOT__b_zero))
                      ? 0x7e00U : (0x7fffU | (0x8000U 
                                              & ((IData)(vlTOPp->src_a) 
                                                 ^ (IData)(vlTOPp->src_b)))));
            } else {
                if ((((IData)(vlTOPp->hp_top__DOT__a_zero) 
                      | (IData)(vlTOPp->hp_top__DOT__b_zero)) 
                     | ((IData)(vlTOPp->hp_top__DOT__a_subN) 
                        & (IData)(vlTOPp->hp_top__DOT__b_subN)))) {
                    vlTOPp->hp_top__DOT__trunc_result 
                        = (0x8000U & ((IData)(vlTOPp->src_a) 
                                      ^ (IData)(vlTOPp->src_b)));
                }
            }
        }
    }
    vlTOPp->hp_top__DOT__trunc_result = (0x8000U & 
                                         ((IData)(vlTOPp->src_a) 
                                          ^ (IData)(vlTOPp->src_b)));
    if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_SNan) 
                  | (IData)(vlTOPp->hp_top__DOT__b_SNan))))) {
        if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_QNan) 
                      | (IData)(vlTOPp->hp_top__DOT__b_QNan))))) {
            if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_inf) 
                          | (IData)(vlTOPp->hp_top__DOT__b_inf))))) {
                if ((1U & (~ (((IData)(vlTOPp->hp_top__DOT__a_zero) 
                               | (IData)(vlTOPp->hp_top__DOT__b_zero)) 
                              | ((IData)(vlTOPp->hp_top__DOT__a_subN) 
                                 & (IData)(vlTOPp->hp_top__DOT__b_subN)))))) {
                    if (vlTOPp->hp_top__DOT__a_subN) {
                        vlTOPp->hp_top__DOT__multiplier__DOT__clz_rin 
                            = (0x3ffU & (IData)(vlTOPp->src_a));
                    } else {
                        if (vlTOPp->hp_top__DOT__b_subN) {
                            vlTOPp->hp_top__DOT__multiplier__DOT__clz_rin 
                                = (0x3ffU & (IData)(vlTOPp->src_b));
                        }
                    }
                }
            }
        }
    }
    if ((4U & (IData)(vlTOPp->operation))) {
        if ((1U & (~ ((IData)(vlTOPp->operation) >> 1U)))) {
            vlTOPp->zero = vlTOPp->hp_top__DOT__mul_res_zero;
            vlTOPp->inf = vlTOPp->hp_top__DOT__mul_res_inf;
            vlTOPp->subN = vlTOPp->hp_top__DOT__mul_res_subN;
            vlTOPp->Norm = vlTOPp->hp_top__DOT__mul_res_Norm;
            vlTOPp->QNan = vlTOPp->hp_top__DOT__mul_res_QNan;
            vlTOPp->SNan = vlTOPp->hp_top__DOT__mul_res_SNan;
        }
    }
    if (((IData)(vlTOPp->Norm) | (IData)(vlTOPp->subN))) {
        if (((((IData)(vlTOPp->zero) | (IData)(vlTOPp->inf)) 
              | (IData)(vlTOPp->SNan)) | (IData)(vlTOPp->QNan))) {
            vlTOPp->res_out = ((0xfc00U & (IData)(vlTOPp->res_out)) 
                               | (0x3ffU & (vlTOPp->hp_top__DOT__rounding_reg 
                                            >> 0xbU)));
        }
    } else {
        vlTOPp->res_out = vlTOPp->hp_top__DOT__trunc_result;
    }
    vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout = 0U;
    vlTOPp->hp_top__DOT__multiplier__DOT__clz__DOT__rin 
        = vlTOPp->hp_top__DOT__multiplier__DOT__clz_rin;
    if ((0U == (0xfU & ((IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rin) 
                        >> 6U)))) {
        vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout 
            = (0xfU & ((IData)(4U) + (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout)));
        vlTOPp->hp_top__DOT__multiplier__DOT__clz__DOT__rin 
            = (0x3ffU & ((IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz__DOT__rin) 
                         << 4U));
    }
    if ((0U == (3U & ((IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rin) 
                      >> 8U)))) {
        vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout 
            = (0xfU & ((IData)(2U) + (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout)));
        vlTOPp->hp_top__DOT__multiplier__DOT__clz__DOT__rin 
            = (0x3ffU & ((IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz__DOT__rin) 
                         << 2U));
    }
    if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rin) 
                  >> 9U)))) {
        vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout 
            = (0xfU & ((IData)(1U) + (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout)));
    }
    vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout 
        = (0xfU & (((IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout) 
                    + (1U & (~ ((IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz__DOT__rin) 
                                >> 8U)))) + (1U & (~ 
                                                   (((IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz__DOT__rin) 
                                                     >> 8U) 
                                                    & ((IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz__DOT__rin) 
                                                       >> 9U))))));
    vlTOPp->hp_top__DOT__multiplier__DOT__a_mant = 0U;
    vlTOPp->hp_top__DOT__multiplier__DOT__b_mant = 0U;
    if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_SNan) 
                  | (IData)(vlTOPp->hp_top__DOT__b_SNan))))) {
        if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_QNan) 
                      | (IData)(vlTOPp->hp_top__DOT__b_QNan))))) {
            if ((1U & (~ ((IData)(vlTOPp->hp_top__DOT__a_inf) 
                          | (IData)(vlTOPp->hp_top__DOT__b_inf))))) {
                if ((1U & (~ (((IData)(vlTOPp->hp_top__DOT__a_zero) 
                               | (IData)(vlTOPp->hp_top__DOT__b_zero)) 
                              | ((IData)(vlTOPp->hp_top__DOT__a_subN) 
                                 & (IData)(vlTOPp->hp_top__DOT__b_subN)))))) {
                    if (vlTOPp->hp_top__DOT__a_subN) {
                        vlTOPp->hp_top__DOT__multiplier__DOT__a_mant 
                            = (0x400U | ((9U >= ((IData)(1U) 
                                                 + (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout)))
                                          ? (0x3ffU 
                                             & ((IData)(vlTOPp->src_a) 
                                                << 
                                                ((IData)(1U) 
                                                 + (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout))))
                                          : 0U));
                        vlTOPp->hp_top__DOT__multiplier__DOT__a_exp 
                            = (0x3fU & ((IData)(0x32U) 
                                        + ((0x1fU & 
                                            ((IData)(vlTOPp->src_a) 
                                             >> 0xaU)) 
                                           - (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout))));
                        vlTOPp->hp_top__DOT__multiplier__DOT__b_exp 
                            = (0x3fU & ((0x1fU & ((IData)(vlTOPp->src_b) 
                                                  >> 0xaU)) 
                                        - (IData)(0xfU)));
                        vlTOPp->hp_top__DOT__multiplier__DOT__b_mant 
                            = (0x400U | (0x3ffU & (IData)(vlTOPp->src_b)));
                    } else {
                        if (vlTOPp->hp_top__DOT__b_subN) {
                            vlTOPp->hp_top__DOT__multiplier__DOT__b_mant 
                                = (0x400U | ((9U >= 
                                              ((IData)(1U) 
                                               + (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout)))
                                              ? (0x3ffU 
                                                 & ((IData)(vlTOPp->src_b) 
                                                    << 
                                                    ((IData)(1U) 
                                                     + (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout))))
                                              : 0U));
                            vlTOPp->hp_top__DOT__multiplier__DOT__b_exp 
                                = (0x3fU & ((IData)(0x32U) 
                                            + ((0x1fU 
                                                & ((IData)(vlTOPp->src_b) 
                                                   >> 0xaU)) 
                                               - (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout))));
                            vlTOPp->hp_top__DOT__multiplier__DOT__a_exp 
                                = (0x3fU & ((0x1fU 
                                             & ((IData)(vlTOPp->src_a) 
                                                >> 0xaU)) 
                                            - (IData)(0xfU)));
                            vlTOPp->hp_top__DOT__multiplier__DOT__a_mant 
                                = (0x400U | (0x3ffU 
                                             & (IData)(vlTOPp->src_a)));
                        } else {
                            vlTOPp->hp_top__DOT__multiplier__DOT__a_exp 
                                = (0x3fU & ((0x1fU 
                                             & ((IData)(vlTOPp->src_a) 
                                                >> 0xaU)) 
                                            - (IData)(0xfU)));
                            vlTOPp->hp_top__DOT__multiplier__DOT__a_mant 
                                = (0x400U | (0x3ffU 
                                             & (IData)(vlTOPp->src_a)));
                            vlTOPp->hp_top__DOT__multiplier__DOT__b_exp 
                                = (0x3fU & ((0x1fU 
                                             & ((IData)(vlTOPp->src_b) 
                                                >> 0xaU)) 
                                            - (IData)(0xfU)));
                            vlTOPp->hp_top__DOT__multiplier__DOT__b_mant 
                                = (0x400U | (0x3ffU 
                                             & (IData)(vlTOPp->src_b)));
                        }
                    }
                }
            }
        }
    }
    vlTOPp->hp_top__DOT__multiplier__DOT__res_mant 
        = (0x3fffffU & ((IData)(vlTOPp->hp_top__DOT__multiplier__DOT__a_mant) 
                        * (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__b_mant)));
    vlTOPp->hp_top__DOT__multiplier__DOT__res_exp = 
        (0x3fU & ((IData)(vlTOPp->hp_top__DOT__multiplier__DOT__a_exp) 
                  + (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__b_exp)));
    if ((0x200000U & vlTOPp->hp_top__DOT__multiplier__DOT__res_mant)) {
        vlTOPp->hp_top__DOT__multiplier__DOT__res_mant 
            = (0x3fffffU & (vlTOPp->hp_top__DOT__multiplier__DOT__res_mant 
                            >> 1U));
        vlTOPp->hp_top__DOT__multiplier__DOT__res_exp 
            = (0x3fU & ((IData)(1U) + (IData)(vlTOPp->hp_top__DOT__multiplier__DOT__res_exp)));
    }
}

void Vhp_top::_eval(Vhp_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhp_top::_eval\n"); );
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_combo__TOP__1(vlSymsp);
    vlTOPp->__Vm_traceActivity[1U] = 1U;
}

VL_INLINE_OPT QData Vhp_top::_change_request(Vhp_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhp_top::_change_request\n"); );
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    return (vlTOPp->_change_request_1(vlSymsp));
}

VL_INLINE_OPT QData Vhp_top::_change_request_1(Vhp_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhp_top::_change_request_1\n"); );
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    // Change detection
    QData __req = false;  // Logically a bool
    return __req;
}

#ifdef VL_DEBUG
void Vhp_top::_eval_debug_assertions() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhp_top::_eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((operation & 0xf8U))) {
        Verilated::overWidthError("operation");}
    if (VL_UNLIKELY((ops_ready & 0xfeU))) {
        Verilated::overWidthError("ops_ready");}
}
#endif  // VL_DEBUG
