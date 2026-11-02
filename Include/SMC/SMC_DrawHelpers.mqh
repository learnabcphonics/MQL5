// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWHELPERS_MQH
#define SMC_DRAWHELPERS_MQH

#include <SMC/SMC_Types.mqh>
#include <SMC/SMC_Palette.mqh>
#include <SMC/SMC_PineDrawings.mqh>
#include <SMC/SMC_ZoneCanvas.mqh>

ENUM_LINE_STYLE SMC_LineStyle(const ENUM_SMC_LINE_STYLE style)
{
   if(style == SMC_DASHED) return STYLE_DASH;
   if(style == SMC_DOTTED) return STYLE_DOT;
   return STYLE_SOLID;
}

string SMC_TimeframeLabel(const ENUM_TIMEFRAMES timeframe)
{
   string label=EnumToString(timeframe);
   StringReplace(label,"PERIOD_","");
   return label;
}

void SMC_DeleteObjectsWithPrefix(const string prefix)
{
   for(int i=ObjectsTotal(0,-1,-1)-1;i>=0;--i)
   {
      string name=ObjectName(0,i,-1,-1);
      if(StringFind(name,prefix)==0)
         SMC_PineDrawingDelete(name);
   }
   SMC_PineDrawingDeletePrefix(prefix);
   SMC_ZoneCanvasRemovePrefix(prefix);
}

void SMC_ClearObjects(const string prefix)
{
   SMC_DeleteObjectsWithPrefix(prefix);
   SMC_ZoneCanvasRelease(prefix);
}

void SMC_MoveObjectPointIfChanged(const string name,const int point,
                              const datetime when,const double price)
{
   if(ObjectFind(0,name)<0)
      return;
   datetime currentTime=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,point);
   double currentPrice=ObjectGetDouble(0,name,OBJPROP_PRICE,point);
   if(currentTime!=when || currentPrice!=price)
      ObjectMove(0,name,point,when,price);
}

void SMC_DrawText(const string name,const datetime when,const double price,
              const string text,const color textColor,const ENUM_ANCHOR_POINT anchor,
              const int fontSize=8,const bool keep=false,
              const int zOrder=100)
{
   SMC_PineLabelSet(name,when,price,text,textColor,anchor,fontSize,keep,zOrder);
}

string SMC_BiasText(const int bias)
{
   if(bias>0) return "BULLISH";
   if(bias<0) return "BEARISH";
   return "UNSET";
}

#endif // SMC_DRAWHELPERS_MQH
