// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWPREMIUMDISCOUNT_MQH
#define SMC_DRAWPREMIUMDISCOUNT_MQH

#include <SMC/SMC_DrawHelpers.mqh>
#include <SMC/SMC_DrawAreas.mqh>
#include <SMC/SMC_DrawZoneHelpers.mqh>

void SMC_DrawPremiumDiscount(const SMC_DrawConfig &config,
                             const PivotState &trailingTop,
                             const PivotState &trailingBottom,
                             const datetime trailingAnchorTime,
                             const datetime lastTime,
                             const int periodSeconds)
{
   if(!config.showPremiumDiscountZones || !trailingTop.initialized ||
      !trailingBottom.initialized ||
      trailingTop.current<=trailingBottom.current)
   {
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Premium");
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Equilibrium");
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Discount");
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Premium_Label");
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Equilibrium_Label");
      SMC_PineDrawingDelete(config.objectPrefix+"PD_Discount_Label");
      SMC_ZoneCanvasRemove(config.objectPrefix+"PD_Premium");
      SMC_ZoneCanvasRemove(config.objectPrefix+"PD_Equilibrium");
      SMC_ZoneCanvasRemove(config.objectPrefix+"PD_Discount");
      return;
   }
   double top=trailingTop.current,bottom=trailingBottom.current;
   datetime start=trailingAnchorTime;
   if(start==0)
      start=(trailingTop.time>trailingBottom.time ?
             trailingTop.time : trailingBottom.time);
   datetime finish=lastTime+periodSeconds*20;
   double premiumBottom=0.95*top+0.05*bottom;
   double eqTop=0.525*top+0.475*bottom;
   double eqBottom=0.525*bottom+0.475*top;
   double discountTop=0.95*bottom+0.05*top;
   SMC_DrawZoneBox(config.objectPrefix+"PD_Premium",start,finish,top,
                   premiumBottom,SMC_COLOR_BEARISH,80,100);
   SMC_DrawZoneBox(config.objectPrefix+"PD_Equilibrium",start,finish,eqTop,
                   eqBottom,SMC_COLOR_EQUILIBRIUM,80,100);
   SMC_DrawZoneBox(config.objectPrefix+"PD_Discount",start,finish,discountTop,
                   bottom,SMC_COLOR_BULLISH,80,100);
   datetime middleTime=start+(finish-start)/2;
   double premiumPrice=SMC_LabelOffsetPrice(
      config.objectPrefix+"PD_Premium",(top+premiumBottom)/2,
      MathAbs(top-premiumBottom));
   double equilibriumPrice=SMC_LabelOffsetPrice(
      config.objectPrefix+"PD_Equilibrium",(eqTop+eqBottom)/2,
      MathAbs(eqTop-eqBottom));
   double discountPrice=SMC_LabelOffsetPrice(
      config.objectPrefix+"PD_Discount",(discountTop+bottom)/2,
      MathAbs(discountTop-bottom));
   SMC_DrawText(config.objectPrefix+"PD_Premium_Label",middleTime,
                premiumPrice,"Premium",SMC_COLOR_LABEL,ANCHOR_CENTER,8,true);
   SMC_DrawText(config.objectPrefix+"PD_Equilibrium_Label",middleTime,
                equilibriumPrice,"Equilibrium",SMC_COLOR_LABEL,
                ANCHOR_CENTER,8,true);
   SMC_DrawText(config.objectPrefix+"PD_Discount_Label",middleTime,
                discountPrice,"Discount",SMC_COLOR_LABEL,ANCHOR_CENTER,8,true);
}

#endif // SMC_DRAWPREMIUMDISCOUNT_MQH
