// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vhp_top__Syms.h"


void Vhp_top::traceChgTop0(void* userp, VerilatedVcd* tracep) {
    Vhp_top__Syms* __restrict vlSymsp = static_cast<Vhp_top__Syms*>(userp);
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Variables
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    {
        vlTOPp->traceChgSub0(userp, tracep);
    }
}

void Vhp_top::traceChgSub0(void* userp, VerilatedVcd* tracep) {
    Vhp_top__Syms* __restrict vlSymsp = static_cast<Vhp_top__Syms*>(userp);
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    vluint32_t* const oldp = tracep->oldp(vlSymsp->__Vm_baseCode + 1);
    if (false && oldp) {}  // Prevent unused
    // Body
    {
        if (VL_UNLIKELY(vlTOPp->__Vm_traceActivity[1U])) {
            tracep->chgBit(oldp+0,(vlTOPp->hp_top__DOT__a_zero));
            tracep->chgBit(oldp+1,(vlTOPp->hp_top__DOT__a_inf));
            tracep->chgBit(oldp+2,(vlTOPp->hp_top__DOT__a_subN));
            tracep->chgBit(oldp+3,(vlTOPp->hp_top__DOT__a_QNan));
            tracep->chgBit(oldp+4,(vlTOPp->hp_top__DOT__a_SNan));
            tracep->chgBit(oldp+5,(vlTOPp->hp_top__DOT__b_zero));
            tracep->chgBit(oldp+6,(vlTOPp->hp_top__DOT__b_inf));
            tracep->chgBit(oldp+7,(vlTOPp->hp_top__DOT__b_subN));
            tracep->chgBit(oldp+8,(vlTOPp->hp_top__DOT__b_QNan));
            tracep->chgBit(oldp+9,(vlTOPp->hp_top__DOT__b_SNan));
            tracep->chgBit(oldp+10,(vlTOPp->hp_top__DOT__mul_res_zero));
            tracep->chgBit(oldp+11,(vlTOPp->hp_top__DOT__mul_res_inf));
            tracep->chgBit(oldp+12,(vlTOPp->hp_top__DOT__mul_res_QNan));
            tracep->chgBit(oldp+13,(vlTOPp->hp_top__DOT__mul_res_SNan));
            tracep->chgSData(oldp+14,(vlTOPp->hp_top__DOT__trunc_result),16);
            tracep->chgCData(oldp+15,(vlTOPp->hp_top__DOT__multiplier__DOT__a_exp),6);
            tracep->chgCData(oldp+16,(vlTOPp->hp_top__DOT__multiplier__DOT__b_exp),6);
            tracep->chgSData(oldp+17,(vlTOPp->hp_top__DOT__multiplier__DOT__a_mant),11);
            tracep->chgSData(oldp+18,(vlTOPp->hp_top__DOT__multiplier__DOT__b_mant),11);
            tracep->chgCData(oldp+19,(vlTOPp->hp_top__DOT__multiplier__DOT__res_exp),6);
            tracep->chgIData(oldp+20,(vlTOPp->hp_top__DOT__multiplier__DOT__res_mant),22);
            tracep->chgSData(oldp+21,(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rin),10);
            tracep->chgCData(oldp+22,(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout),4);
            tracep->chgSData(oldp+23,(vlTOPp->hp_top__DOT__multiplier__DOT__clz__DOT__rin),10);
        }
        tracep->chgSData(oldp+24,(vlTOPp->src_a),16);
        tracep->chgSData(oldp+25,(vlTOPp->src_b),16);
        tracep->chgCData(oldp+26,(vlTOPp->operation),3);
        tracep->chgBit(oldp+27,(vlTOPp->ops_ready));
        tracep->chgSData(oldp+28,(vlTOPp->res_out),16);
        tracep->chgBit(oldp+29,(vlTOPp->zero));
        tracep->chgBit(oldp+30,(vlTOPp->inf));
        tracep->chgBit(oldp+31,(vlTOPp->subN));
        tracep->chgBit(oldp+32,(vlTOPp->Norm));
        tracep->chgBit(oldp+33,(vlTOPp->QNan));
        tracep->chgBit(oldp+34,(vlTOPp->SNan));
        tracep->chgBit(oldp+35,(((~ (IData)((0x1fU 
                                             == (0x1fU 
                                                 & ((IData)(vlTOPp->src_a) 
                                                    >> 0xaU))))) 
                                 & (0U != (0x1fU & 
                                           ((IData)(vlTOPp->src_a) 
                                            >> 0xaU))))));
        tracep->chgBit(oldp+36,(((~ (IData)((0x1fU 
                                             == (0x1fU 
                                                 & ((IData)(vlTOPp->src_b) 
                                                    >> 0xaU))))) 
                                 & (0U != (0x1fU & 
                                           ((IData)(vlTOPp->src_b) 
                                            >> 0xaU))))));
        tracep->chgBit(oldp+37,((0x1fU == (0x1fU & 
                                           ((IData)(vlTOPp->src_a) 
                                            >> 0xaU)))));
        tracep->chgBit(oldp+38,((1U & (~ (IData)((0U 
                                                  != 
                                                  (0x1fU 
                                                   & ((IData)(vlTOPp->src_a) 
                                                      >> 0xaU))))))));
        tracep->chgBit(oldp+39,((1U & (~ (IData)((0U 
                                                  != 
                                                  (0x3ffU 
                                                   & (IData)(vlTOPp->src_a))))))));
        tracep->chgBit(oldp+40,((0x1fU == (0x1fU & 
                                           ((IData)(vlTOPp->src_b) 
                                            >> 0xaU)))));
        tracep->chgBit(oldp+41,((1U & (~ (IData)((0U 
                                                  != 
                                                  (0x1fU 
                                                   & ((IData)(vlTOPp->src_b) 
                                                      >> 0xaU))))))));
        tracep->chgBit(oldp+42,((1U & (~ (IData)((0U 
                                                  != 
                                                  (0x3ffU 
                                                   & (IData)(vlTOPp->src_b))))))));
        tracep->chgBit(oldp+43,((1U & (IData)(vlTOPp->operation))));
    }
}

void Vhp_top::traceCleanup(void* userp, VerilatedVcd* /*unused*/) {
    Vhp_top__Syms* __restrict vlSymsp = static_cast<Vhp_top__Syms*>(userp);
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    {
        vlSymsp->__Vm_activity = false;
        vlTOPp->__Vm_traceActivity[0U] = 0U;
        vlTOPp->__Vm_traceActivity[1U] = 0U;
    }
}
