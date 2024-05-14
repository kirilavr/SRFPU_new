// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vhp_top__Syms.h"


//======================

void Vhp_top::trace(VerilatedVcdC* tfp, int, int) {
    tfp->spTrace()->addInitCb(&traceInit, __VlSymsp);
    traceRegister(tfp->spTrace());
}

void Vhp_top::traceInit(void* userp, VerilatedVcd* tracep, uint32_t code) {
    // Callback from tracep->open()
    Vhp_top__Syms* __restrict vlSymsp = static_cast<Vhp_top__Syms*>(userp);
    if (!Verilated::calcUnusedSigs()) {
        VL_FATAL_MT(__FILE__, __LINE__, __FILE__,
                        "Turning on wave traces requires Verilated::traceEverOn(true) call before time 0.");
    }
    vlSymsp->__Vm_baseCode = code;
    tracep->module(vlSymsp->name());
    tracep->scopeEscape(' ');
    Vhp_top::traceInitTop(vlSymsp, tracep);
    tracep->scopeEscape('.');
}

//======================


void Vhp_top::traceInitTop(void* userp, VerilatedVcd* tracep) {
    Vhp_top__Syms* __restrict vlSymsp = static_cast<Vhp_top__Syms*>(userp);
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    {
        vlTOPp->traceInitSub0(userp, tracep);
    }
}

void Vhp_top::traceInitSub0(void* userp, VerilatedVcd* tracep) {
    Vhp_top__Syms* __restrict vlSymsp = static_cast<Vhp_top__Syms*>(userp);
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    const int c = vlSymsp->__Vm_baseCode;
    if (false && tracep && c) {}  // Prevent unused
    // Body
    {
        tracep->declBus(c+25,"src_a", false,-1, 15,0);
        tracep->declBus(c+26,"src_b", false,-1, 15,0);
        tracep->declBus(c+27,"operation", false,-1, 2,0);
        tracep->declBit(c+28,"ops_ready", false,-1);
        tracep->declBus(c+29,"res_out", false,-1, 15,0);
        tracep->declBit(c+30,"zero", false,-1);
        tracep->declBit(c+31,"inf", false,-1);
        tracep->declBit(c+32,"subN", false,-1);
        tracep->declBit(c+33,"Norm", false,-1);
        tracep->declBit(c+34,"QNan", false,-1);
        tracep->declBit(c+35,"SNan", false,-1);
        tracep->declBus(c+25,"hp_top src_a", false,-1, 15,0);
        tracep->declBus(c+26,"hp_top src_b", false,-1, 15,0);
        tracep->declBus(c+27,"hp_top operation", false,-1, 2,0);
        tracep->declBit(c+28,"hp_top ops_ready", false,-1);
        tracep->declBus(c+29,"hp_top res_out", false,-1, 15,0);
        tracep->declBit(c+30,"hp_top zero", false,-1);
        tracep->declBit(c+31,"hp_top inf", false,-1);
        tracep->declBit(c+32,"hp_top subN", false,-1);
        tracep->declBit(c+33,"hp_top Norm", false,-1);
        tracep->declBit(c+34,"hp_top QNan", false,-1);
        tracep->declBit(c+35,"hp_top SNan", false,-1);
        tracep->declBus(c+45,"hp_top ADD_RN", false,-1, 2,0);
        tracep->declBus(c+46,"hp_top SUB_RN", false,-1, 2,0);
        tracep->declBus(c+47,"hp_top MUL_RN", false,-1, 2,0);
        tracep->declBus(c+48,"hp_top DIV_RN", false,-1, 2,0);
        tracep->declBus(c+49,"hp_top ADD_SR", false,-1, 2,0);
        tracep->declBus(c+50,"hp_top SUB_SR", false,-1, 2,0);
        tracep->declBus(c+51,"hp_top MUL_SR", false,-1, 2,0);
        tracep->declBus(c+52,"hp_top DIV_SR", false,-1, 2,0);
        tracep->declBit(c+1,"hp_top a_zero", false,-1);
        tracep->declBit(c+2,"hp_top a_inf", false,-1);
        tracep->declBit(c+3,"hp_top a_subN", false,-1);
        tracep->declBit(c+36,"hp_top a_Norm", false,-1);
        tracep->declBit(c+4,"hp_top a_QNan", false,-1);
        tracep->declBit(c+5,"hp_top a_SNan", false,-1);
        tracep->declBit(c+6,"hp_top b_zero", false,-1);
        tracep->declBit(c+7,"hp_top b_inf", false,-1);
        tracep->declBit(c+8,"hp_top b_subN", false,-1);
        tracep->declBit(c+37,"hp_top b_Norm", false,-1);
        tracep->declBit(c+9,"hp_top b_QNan", false,-1);
        tracep->declBit(c+10,"hp_top b_SNan", false,-1);
        tracep->declBit(c+11,"hp_top mul_res_zero", false,-1);
        tracep->declBit(c+12,"hp_top mul_res_inf", false,-1);
        tracep->declBit(c+53,"hp_top mul_res_subN", false,-1);
        tracep->declBit(c+54,"hp_top mul_res_Norm", false,-1);
        tracep->declBit(c+13,"hp_top mul_res_QNan", false,-1);
        tracep->declBit(c+14,"hp_top mul_res_SNan", false,-1);
        tracep->declBus(c+55,"hp_top rounding_reg", false,-1, 21,0);
        tracep->declBus(c+56,"hp_top rounded_result", false,-1, 9,0);
        tracep->declBus(c+15,"hp_top trunc_result", false,-1, 15,0);
        tracep->declBit(c+57,"hp_top mul_res_ready", false,-1);
        tracep->declBit(c+57,"hp_top round_res_ready", false,-1);
        tracep->declBus(c+25,"hp_top classifier_1 f", false,-1, 15,0);
        tracep->declBit(c+1,"hp_top classifier_1 zero", false,-1);
        tracep->declBit(c+2,"hp_top classifier_1 inf", false,-1);
        tracep->declBit(c+3,"hp_top classifier_1 subN", false,-1);
        tracep->declBit(c+36,"hp_top classifier_1 Norm", false,-1);
        tracep->declBit(c+4,"hp_top classifier_1 QNan", false,-1);
        tracep->declBit(c+5,"hp_top classifier_1 SNan", false,-1);
        tracep->declBit(c+38,"hp_top classifier_1 expOnes", false,-1);
        tracep->declBit(c+39,"hp_top classifier_1 expZeroes", false,-1);
        tracep->declBit(c+40,"hp_top classifier_1 sigZeroes", false,-1);
        tracep->declBus(c+26,"hp_top classifier_2 f", false,-1, 15,0);
        tracep->declBit(c+6,"hp_top classifier_2 zero", false,-1);
        tracep->declBit(c+7,"hp_top classifier_2 inf", false,-1);
        tracep->declBit(c+8,"hp_top classifier_2 subN", false,-1);
        tracep->declBit(c+37,"hp_top classifier_2 Norm", false,-1);
        tracep->declBit(c+9,"hp_top classifier_2 QNan", false,-1);
        tracep->declBit(c+10,"hp_top classifier_2 SNan", false,-1);
        tracep->declBit(c+41,"hp_top classifier_2 expOnes", false,-1);
        tracep->declBit(c+42,"hp_top classifier_2 expZeroes", false,-1);
        tracep->declBit(c+43,"hp_top classifier_2 sigZeroes", false,-1);
        tracep->declBus(c+25,"hp_top multiplier a_src", false,-1, 15,0);
        tracep->declBit(c+1,"hp_top multiplier a_zero", false,-1);
        tracep->declBit(c+2,"hp_top multiplier a_inf", false,-1);
        tracep->declBit(c+3,"hp_top multiplier a_subN", false,-1);
        tracep->declBit(c+36,"hp_top multiplier a_Norm", false,-1);
        tracep->declBit(c+4,"hp_top multiplier a_QNan", false,-1);
        tracep->declBit(c+5,"hp_top multiplier a_SNan", false,-1);
        tracep->declBus(c+26,"hp_top multiplier b_src", false,-1, 15,0);
        tracep->declBit(c+6,"hp_top multiplier b_zero", false,-1);
        tracep->declBit(c+7,"hp_top multiplier b_inf", false,-1);
        tracep->declBit(c+8,"hp_top multiplier b_subN", false,-1);
        tracep->declBit(c+37,"hp_top multiplier b_Norm", false,-1);
        tracep->declBit(c+9,"hp_top multiplier b_QNan", false,-1);
        tracep->declBit(c+10,"hp_top multiplier b_SNan", false,-1);
        tracep->declBus(c+15,"hp_top multiplier result", false,-1, 15,0);
        tracep->declBus(c+55,"hp_top multiplier round_mant", false,-1, 21,0);
        tracep->declBit(c+11,"hp_top multiplier zero", false,-1);
        tracep->declBit(c+12,"hp_top multiplier inf", false,-1);
        tracep->declBit(c+53,"hp_top multiplier subnormal", false,-1);
        tracep->declBit(c+54,"hp_top multiplier normal", false,-1);
        tracep->declBit(c+13,"hp_top multiplier QNan", false,-1);
        tracep->declBit(c+14,"hp_top multiplier SNan", false,-1);
        tracep->declBus(c+16,"hp_top multiplier a_exp", false,-1, 5,0);
        tracep->declBus(c+17,"hp_top multiplier b_exp", false,-1, 5,0);
        tracep->declBus(c+18,"hp_top multiplier a_mant", false,-1, 10,0);
        tracep->declBus(c+19,"hp_top multiplier b_mant", false,-1, 10,0);
        tracep->declBus(c+20,"hp_top multiplier res_exp", false,-1, 5,0);
        tracep->declBus(c+21,"hp_top multiplier res_mant", false,-1, 21,0);
        tracep->declBus(c+22,"hp_top multiplier clz_rin", false,-1, 9,0);
        tracep->declBus(c+23,"hp_top multiplier clz_rout", false,-1, 3,0);
        tracep->declBus(c+22,"hp_top multiplier clz in", false,-1, 9,0);
        tracep->declBus(c+23,"hp_top multiplier clz out", false,-1, 3,0);
        tracep->declBus(c+24,"hp_top multiplier clz rin", false,-1, 9,0);
        tracep->declBit(c+44,"hp_top rounding mode", false,-1);
        tracep->declBus(c+55,"hp_top rounding mantissa", false,-1, 21,0);
        tracep->declBus(c+56,"hp_top rounding rounded", false,-1, 9,0);
    }
}

void Vhp_top::traceRegister(VerilatedVcd* tracep) {
    // Body
    {
        tracep->addFullCb(&traceFullTop0, __VlSymsp);
        tracep->addChgCb(&traceChgTop0, __VlSymsp);
        tracep->addCleanupCb(&traceCleanup, __VlSymsp);
    }
}

void Vhp_top::traceFullTop0(void* userp, VerilatedVcd* tracep) {
    Vhp_top__Syms* __restrict vlSymsp = static_cast<Vhp_top__Syms*>(userp);
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    {
        vlTOPp->traceFullSub0(userp, tracep);
    }
}

void Vhp_top::traceFullSub0(void* userp, VerilatedVcd* tracep) {
    Vhp_top__Syms* __restrict vlSymsp = static_cast<Vhp_top__Syms*>(userp);
    Vhp_top* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    vluint32_t* const oldp = tracep->oldp(vlSymsp->__Vm_baseCode);
    if (false && oldp) {}  // Prevent unused
    // Body
    {
        tracep->fullBit(oldp+1,(vlTOPp->hp_top__DOT__a_zero));
        tracep->fullBit(oldp+2,(vlTOPp->hp_top__DOT__a_inf));
        tracep->fullBit(oldp+3,(vlTOPp->hp_top__DOT__a_subN));
        tracep->fullBit(oldp+4,(vlTOPp->hp_top__DOT__a_QNan));
        tracep->fullBit(oldp+5,(vlTOPp->hp_top__DOT__a_SNan));
        tracep->fullBit(oldp+6,(vlTOPp->hp_top__DOT__b_zero));
        tracep->fullBit(oldp+7,(vlTOPp->hp_top__DOT__b_inf));
        tracep->fullBit(oldp+8,(vlTOPp->hp_top__DOT__b_subN));
        tracep->fullBit(oldp+9,(vlTOPp->hp_top__DOT__b_QNan));
        tracep->fullBit(oldp+10,(vlTOPp->hp_top__DOT__b_SNan));
        tracep->fullBit(oldp+11,(vlTOPp->hp_top__DOT__mul_res_zero));
        tracep->fullBit(oldp+12,(vlTOPp->hp_top__DOT__mul_res_inf));
        tracep->fullBit(oldp+13,(vlTOPp->hp_top__DOT__mul_res_QNan));
        tracep->fullBit(oldp+14,(vlTOPp->hp_top__DOT__mul_res_SNan));
        tracep->fullSData(oldp+15,(vlTOPp->hp_top__DOT__trunc_result),16);
        tracep->fullCData(oldp+16,(vlTOPp->hp_top__DOT__multiplier__DOT__a_exp),6);
        tracep->fullCData(oldp+17,(vlTOPp->hp_top__DOT__multiplier__DOT__b_exp),6);
        tracep->fullSData(oldp+18,(vlTOPp->hp_top__DOT__multiplier__DOT__a_mant),11);
        tracep->fullSData(oldp+19,(vlTOPp->hp_top__DOT__multiplier__DOT__b_mant),11);
        tracep->fullCData(oldp+20,(vlTOPp->hp_top__DOT__multiplier__DOT__res_exp),6);
        tracep->fullIData(oldp+21,(vlTOPp->hp_top__DOT__multiplier__DOT__res_mant),22);
        tracep->fullSData(oldp+22,(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rin),10);
        tracep->fullCData(oldp+23,(vlTOPp->hp_top__DOT__multiplier__DOT__clz_rout),4);
        tracep->fullSData(oldp+24,(vlTOPp->hp_top__DOT__multiplier__DOT__clz__DOT__rin),10);
        tracep->fullSData(oldp+25,(vlTOPp->src_a),16);
        tracep->fullSData(oldp+26,(vlTOPp->src_b),16);
        tracep->fullCData(oldp+27,(vlTOPp->operation),3);
        tracep->fullBit(oldp+28,(vlTOPp->ops_ready));
        tracep->fullSData(oldp+29,(vlTOPp->res_out),16);
        tracep->fullBit(oldp+30,(vlTOPp->zero));
        tracep->fullBit(oldp+31,(vlTOPp->inf));
        tracep->fullBit(oldp+32,(vlTOPp->subN));
        tracep->fullBit(oldp+33,(vlTOPp->Norm));
        tracep->fullBit(oldp+34,(vlTOPp->QNan));
        tracep->fullBit(oldp+35,(vlTOPp->SNan));
        tracep->fullBit(oldp+36,(((~ (IData)((0x1fU 
                                              == (0x1fU 
                                                  & ((IData)(vlTOPp->src_a) 
                                                     >> 0xaU))))) 
                                  & (0U != (0x1fU & 
                                            ((IData)(vlTOPp->src_a) 
                                             >> 0xaU))))));
        tracep->fullBit(oldp+37,(((~ (IData)((0x1fU 
                                              == (0x1fU 
                                                  & ((IData)(vlTOPp->src_b) 
                                                     >> 0xaU))))) 
                                  & (0U != (0x1fU & 
                                            ((IData)(vlTOPp->src_b) 
                                             >> 0xaU))))));
        tracep->fullBit(oldp+38,((0x1fU == (0x1fU & 
                                            ((IData)(vlTOPp->src_a) 
                                             >> 0xaU)))));
        tracep->fullBit(oldp+39,((1U & (~ (IData)((0U 
                                                   != 
                                                   (0x1fU 
                                                    & ((IData)(vlTOPp->src_a) 
                                                       >> 0xaU))))))));
        tracep->fullBit(oldp+40,((1U & (~ (IData)((0U 
                                                   != 
                                                   (0x3ffU 
                                                    & (IData)(vlTOPp->src_a))))))));
        tracep->fullBit(oldp+41,((0x1fU == (0x1fU & 
                                            ((IData)(vlTOPp->src_b) 
                                             >> 0xaU)))));
        tracep->fullBit(oldp+42,((1U & (~ (IData)((0U 
                                                   != 
                                                   (0x1fU 
                                                    & ((IData)(vlTOPp->src_b) 
                                                       >> 0xaU))))))));
        tracep->fullBit(oldp+43,((1U & (~ (IData)((0U 
                                                   != 
                                                   (0x3ffU 
                                                    & (IData)(vlTOPp->src_b))))))));
        tracep->fullBit(oldp+44,((1U & (IData)(vlTOPp->operation))));
        tracep->fullCData(oldp+45,(0U),3);
        tracep->fullCData(oldp+46,(2U),3);
        tracep->fullCData(oldp+47,(4U),3);
        tracep->fullCData(oldp+48,(6U),3);
        tracep->fullCData(oldp+49,(1U),3);
        tracep->fullCData(oldp+50,(3U),3);
        tracep->fullCData(oldp+51,(5U),3);
        tracep->fullCData(oldp+52,(7U),3);
        tracep->fullBit(oldp+53,(vlTOPp->hp_top__DOT__mul_res_subN));
        tracep->fullBit(oldp+54,(vlTOPp->hp_top__DOT__mul_res_Norm));
        tracep->fullIData(oldp+55,(vlTOPp->hp_top__DOT__rounding_reg),22);
        tracep->fullSData(oldp+56,((0x3ffU & (vlTOPp->hp_top__DOT__rounding_reg 
                                              >> 0xbU))),10);
        tracep->fullBit(oldp+57,(0U));
    }
}
