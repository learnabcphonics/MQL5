// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWHELPERS_MQH
#define SMC_DRAWHELPERS_MQH

#include <SMC/SMC_Types.mqh>
#include <SMC/SMC_Palette.mqh>

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
         ObjectDelete(0,name);
   }
}

int SMC_ZoneZOrder(const string objectName)
{
   if(StringFind(objectName,"PL_")==0)
      return -50;
   if(StringFind(objectName,"PD_")==0)
      return -40;
   if(StringFind(objectName,"FVG_")==0)
      return -30;
   if(StringFind(objectName,"OB_")==0)
      return -20;
   if(StringFind(objectName,"STR_")==0)
      return 0;
   if(StringFind(objectName,"SW_")==0)
      return 0;
   return -10;
}

double SMC_LabelOffsetPrice(const string objectName,const double basePrice,const double span)
{
   double step=MathMax(0.000001,MathAbs(span)*0.08);
   if(StringFind(objectName,"OB_")==0)
      return basePrice+step;
   if(StringFind(objectName,"FVG_")==0)
      return basePrice+step*0.5;
   if(StringFind(objectName,"PD_")==0)
      return basePrice+step*0.75;
   return basePrice;
}

bool SMC_ZoneRectanglesOverlap(const datetime leftA,const datetime rightA,
                               const double topA,const double bottomA,
                               const datetime leftB,const datetime rightB,
                               const double topB,const double bottomB)
{
   if(rightA<=leftB || rightB<=leftA)
      return false;
   double highA=MathMax(topA,bottomA);
   double lowA=MathMin(topA,bottomA);
   double highB=MathMax(topB,bottomB);
   double lowB=MathMin(topB,bottomB);
   return !(highA<=lowB || highB<=lowA);
}

void SMC_ClearObjects(const string prefix)
{
   SMC_DeleteObjectsWithPrefix(prefix);
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
              const int fontSize=8)
{
   if(ObjectFind(0,name)<0 && !ObjectCreate(0,name,OBJ_TEXT,0,when,price))
      return;
   SMC_MoveObjectPointIfChanged(name,0,when,price);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontSize);
   ObjectSetInteger(0,name,OBJPROP_COLOR,textColor);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,100);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
}

string SMC_BiasText(const int bias)
{
   if(bias>0) return "BULLISH";
   if(bias<0) return "BEARISH";
   return "UNSET";
}

#endif // SMC_DRAWHELPERS_MQH
