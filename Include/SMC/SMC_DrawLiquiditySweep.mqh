// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWLIQUIDITYSWEEP_MQH
#define SMC_DRAWLIQUIDITYSWEEP_MQH

#include <SMC/SMC_DrawHelpers.mqh>

void SMC_DrawLiquiditySweep(const SMC_DrawConfig &config,
                            const SMC_LiquiditySweepEvent &event)
{
   if(!event.valid)
      return;
   string kind=(event.high ? "BSL" : "SSL");
   string id=(config.mode==SMC_HISTORICAL ?
              IntegerToString((int)event.time) : "Current");
   string name=config.objectPrefix+"LIQ_SWEEP_"+kind+"_"+id;
   string label=SMC_TimeframeLabel(config.chartTimeframe)+" "+kind+" Sweep";
   color eventColor=(event.high ? SMC_COLOR_BEARISH : SMC_COLOR_BULLISH);
   SMC_DrawText(name,event.time,event.wickExtreme,label,eventColor,
                event.high ? ANCHOR_LOWER : ANCHOR_UPPER,8,true);
}

#endif // SMC_DRAWLIQUIDITYSWEEP_MQH
