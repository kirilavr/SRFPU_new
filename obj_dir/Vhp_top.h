// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary design header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef _VHP_TOP_H_
#define _VHP_TOP_H_  // guard

#include "verilated.h"

//==========

class Vhp_top__Syms;
class Vhp_top_VerilatedVcd;


//----------

VL_MODULE(Vhp_top) {
  public:
    
    // PORTS
    // The application code writes and reads these signals to
    // propagate new values into/out from the Verilated model.
    VL_IN8(operation,2,0);
    VL_IN8(ops_ready,0,0);
    VL_OUT8(zero,0,0);
    VL_OUT8(inf,0,0);
    VL_OUT8(subN,0,0);
    VL_OUT8(Norm,0,0);
    VL_OUT8(QNan,0,0);
    VL_OUT8(SNan,0,0);
    VL_IN16(src_a,15,0);
    VL_IN16(src_b,15,0);
    VL_OUT16(res_out,15,0);
    
    // LOCAL SIGNALS
    // Internals; generally not touched by application code
    CData/*0:0*/ hp_top__DOT__a_zero;
    CData/*0:0*/ hp_top__DOT__a_inf;
    CData/*0:0*/ hp_top__DOT__a_subN;
    CData/*0:0*/ hp_top__DOT__a_QNan;
    CData/*0:0*/ hp_top__DOT__a_SNan;
    CData/*0:0*/ hp_top__DOT__b_zero;
    CData/*0:0*/ hp_top__DOT__b_inf;
    CData/*0:0*/ hp_top__DOT__b_subN;
    CData/*0:0*/ hp_top__DOT__b_QNan;
    CData/*0:0*/ hp_top__DOT__b_SNan;
    CData/*0:0*/ hp_top__DOT__mul_res_zero;
    CData/*0:0*/ hp_top__DOT__mul_res_inf;
    CData/*0:0*/ hp_top__DOT__mul_res_subN;
    CData/*0:0*/ hp_top__DOT__mul_res_Norm;
    CData/*0:0*/ hp_top__DOT__mul_res_QNan;
    CData/*0:0*/ hp_top__DOT__mul_res_SNan;
    CData/*5:0*/ hp_top__DOT__multiplier__DOT__a_exp;
    CData/*5:0*/ hp_top__DOT__multiplier__DOT__b_exp;
    CData/*5:0*/ hp_top__DOT__multiplier__DOT__res_exp;
    CData/*3:0*/ hp_top__DOT__multiplier__DOT__clz_rout;
    SData/*15:0*/ hp_top__DOT__trunc_result;
    SData/*10:0*/ hp_top__DOT__multiplier__DOT__a_mant;
    SData/*10:0*/ hp_top__DOT__multiplier__DOT__b_mant;
    SData/*9:0*/ hp_top__DOT__multiplier__DOT__clz_rin;
    SData/*9:0*/ hp_top__DOT__multiplier__DOT__clz__DOT__rin;
    IData/*21:0*/ hp_top__DOT__rounding_reg;
    IData/*21:0*/ hp_top__DOT__multiplier__DOT__res_mant;
    
    // LOCAL VARIABLES
    // Internals; generally not touched by application code
    CData/*0:0*/ __Vm_traceActivity[2];
    
    // INTERNAL VARIABLES
    // Internals; generally not touched by application code
    Vhp_top__Syms* __VlSymsp;  // Symbol table
    
    // CONSTRUCTORS
  private:
    VL_UNCOPYABLE(Vhp_top);  ///< Copying not allowed
  public:
    /// Construct the model; called by application code
    /// The special name  may be used to make a wrapper with a
    /// single model invisible with respect to DPI scope names.
    Vhp_top(const char* name = "TOP");
    /// Destroy the model; called (often implicitly) by application code
    ~Vhp_top();
    /// Trace signals in the model; called by application code
    void trace(VerilatedVcdC* tfp, int levels, int options = 0);
    
    // API METHODS
    /// Evaluate the model.  Application must call when inputs change.
    void eval() { eval_step(); }
    /// Evaluate when calling multiple units/models per time step.
    void eval_step();
    /// Evaluate at end of a timestep for tracing, when using eval_step().
    /// Application must call after all eval() and before time changes.
    void eval_end_step() {}
    /// Simulation complete, run final blocks.  Application must call on completion.
    void final();
    
    // INTERNAL METHODS
  private:
    static void _eval_initial_loop(Vhp_top__Syms* __restrict vlSymsp);
  public:
    void __Vconfigure(Vhp_top__Syms* symsp, bool first);
  private:
    static QData _change_request(Vhp_top__Syms* __restrict vlSymsp);
    static QData _change_request_1(Vhp_top__Syms* __restrict vlSymsp);
  public:
    static void _combo__TOP__1(Vhp_top__Syms* __restrict vlSymsp);
  private:
    void _ctor_var_reset() VL_ATTR_COLD;
  public:
    static void _eval(Vhp_top__Syms* __restrict vlSymsp);
  private:
#ifdef VL_DEBUG
    void _eval_debug_assertions();
#endif  // VL_DEBUG
  public:
    static void _eval_initial(Vhp_top__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _eval_settle(Vhp_top__Syms* __restrict vlSymsp) VL_ATTR_COLD;
  private:
    static void traceChgSub0(void* userp, VerilatedVcd* tracep);
    static void traceChgTop0(void* userp, VerilatedVcd* tracep);
    static void traceCleanup(void* userp, VerilatedVcd* /*unused*/);
    static void traceFullSub0(void* userp, VerilatedVcd* tracep) VL_ATTR_COLD;
    static void traceFullTop0(void* userp, VerilatedVcd* tracep) VL_ATTR_COLD;
    static void traceInitSub0(void* userp, VerilatedVcd* tracep) VL_ATTR_COLD;
    static void traceInitTop(void* userp, VerilatedVcd* tracep) VL_ATTR_COLD;
    void traceRegister(VerilatedVcd* tracep) VL_ATTR_COLD;
    static void traceInit(void* userp, VerilatedVcd* tracep, uint32_t code) VL_ATTR_COLD;
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

//----------


#endif  // guard
