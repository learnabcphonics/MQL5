// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWAREAS_MQH
#define SMC_DRAWAREAS_MQH

#include <SMC/SMC_DrawHelpers.mqh>

void SMC_DrawZoneBox(const string name,const datetime startTime,
                     const datetime endTime,const double top,
                     const double bottom,const color zoneColor,
                     const int fillTransparency=80,
                     const int borderTransparency=-1,const bool keep=true)
{
   if(startTime<=0 || endTime<=startTime ||
      !MathIsValidNumber(top) || !MathIsValidNumber(bottom) || top==bottom)
   {
      SMC_PineDrawingDelete(name);
      SMC_ZoneCanvasRemove(name);
      return;
   }
   double zoneTop=MathMax(top,bottom);
   double zoneBottom=MathMin(top,bottom);
   int effectiveBorderTransparency=borderTransparency<0 ?
                                  fillTransparency : borderTransparency;
   SMC_ZoneCanvasUpsert(name,startTime,endTime,zoneTop,zoneBottom,zoneColor,
                        fillTransparency,effectiveBorderTransparency,keep);
   if(ObjectFind(0,name)>=0)
   {
      bool fillEnabled=ObjectGetInteger(0,name,OBJPROP_FILL)!=0;
      bool backgroundMode=ObjectGetInteger(0,name,OBJPROP_BACK)!=0;
      if(fillEnabled || !backgroundMode)
         SMC_PineDrawingDelete(name);
   }
   if(ObjectFind(0,name)<0 &&
      !ObjectCreate(0,name,OBJ_RECTANGLE,0,startTime,zoneTop,endTime,zoneBottom))
   {
      SMC_ZoneCanvasRemove(name);
      PrintFormat("SMC: unable to create zone bounds object '%s' (error=%d).",
                  name,GetLastError());
      return;
   }
   SMC_MoveObjectPointIfChanged(name,0,startTime,zoneTop);
   SMC_MoveObjectPointIfChanged(name,1,endTime,zoneBottom);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrNONE);
   ObjectSetInteger(0,name,OBJPROP_FILL,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,SMC_ZoneZOrder(name));
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
}

#endif // SMC_DRAWAREAS_MQH
