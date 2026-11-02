// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWFVG_MQH
#define SMC_DRAWFVG_MQH

#include <SMC/SMC_DrawHelpers.mqh>
#include <SMC/SMC_DrawAreas.mqh>
#include <SMC/SMC_DrawZoneHelpers.mqh>

void SMC_DrawFairValueGap(const SMC_DrawConfig &config,
                          const FairValueGapState &gap,
                          const color zoneColor)
{
   string id=(gap.bias>0 ? "Bull_" : "Bear_")+
             IntegerToString((int)gap.time);
   string zoneName=config.objectPrefix+"FVG_"+id;
   bool hasOverlap=false;
   for(int i=ObjectsTotal(0,-1,-1)-1;i>=0;--i)
   {
      string name=ObjectName(0,i,-1,-1);
      if(StringFind(name,config.objectPrefix+"OB_")==0 &&
         ObjectFind(0,name)>=0 &&
         ObjectGetInteger(0,name,OBJPROP_TYPE)==(int)OBJ_RECTANGLE)
      {
         datetime obLeft=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,0);
         datetime obRight=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,1);
         double obTop=ObjectGetDouble(0,name,OBJPROP_PRICE,0);
         double obBottom=ObjectGetDouble(0,name,OBJPROP_PRICE,1);
         if(SMC_ZoneRectanglesOverlap(gap.left,gap.right,gap.top,gap.bottom,
                                     obLeft,obRight,obTop,obBottom))
         {
            hasOverlap=true;
            break;
         }
      }
   }
   if(hasOverlap)
   {
      SMC_PineDrawingDelete(zoneName);
      SMC_PineDrawingDelete(zoneName+"_1");
      SMC_PineDrawingDelete(zoneName+"_2");
      SMC_PineDrawingDelete(zoneName+"_Label");
      return;
   }
   SMC_PineDrawingDelete(zoneName+"_1");
   SMC_PineDrawingDelete(zoneName+"_2");
   SMC_DrawZoneBox(zoneName,gap.left,gap.right,gap.top,gap.bottom,
                   zoneColor,70,70,false);
   datetime middleTime=gap.left+(gap.right-gap.left)/2;
   double middlePrice=(gap.top+gap.bottom)*0.5;
   double labelPrice=SMC_LabelOffsetPrice(zoneName,middlePrice,
                                          MathAbs(gap.top-gap.bottom));
   string label=SMC_TimeframeLabel(config.chartTimeframe)+" "+
                (gap.bias>0 ? "Bullish FVG" : "Bearish FVG");
   SMC_DrawText(zoneName+"_Label",middleTime,labelPrice,label,
                SMC_COLOR_LABEL,ANCHOR_CENTER);
}

void SMC_DeleteFairValueGap(const SMC_DrawConfig &config,
                            const FairValueGapState &gap)
{
   string id=(gap.bias>0 ? "Bull_" : "Bear_")+
             IntegerToString((int)gap.time);
   string zoneName=config.objectPrefix+"FVG_"+id;
   SMC_PineDrawingDelete(zoneName);
   SMC_PineDrawingDelete(zoneName+"_1");
   SMC_PineDrawingDelete(zoneName+"_2");
   SMC_PineDrawingDelete(zoneName+"_Label");
}

#endif // SMC_DRAWFVG_MQH
