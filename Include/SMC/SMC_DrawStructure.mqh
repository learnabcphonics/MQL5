// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWSTRUCTURE_MQH
#define SMC_DRAWSTRUCTURE_MQH

#include <SMC/SMC_DrawHelpers.mqh>

void SMC_UpdateMarketBiasLabel(const SMC_DrawConfig &config,const int swingBias,
                           const int internalBias)
{
   string name=config.objectPrefix+"BIAS";
   if(!config.showMarketBias)
   {
      ObjectDelete(0,name);
      return;
   }
   if(ObjectFind(0,name)<0 && !ObjectCreate(0,name,OBJ_LABEL,0,0,0))
      return;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,10);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,40);
   ObjectSetInteger(0,name,OBJPROP_COLOR,
                    swingBias>0 ? SMC_COLOR_BULLISH :
                    (swingBias<0 ? SMC_COLOR_BEARISH : SMC_COLOR_EQUILIBRIUM));
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,10);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
   ObjectSetString(0,name,OBJPROP_TEXT,
                   "SMC ["+SMC_TimeframeLabel(config.chartTimeframe)+
                   "] Bias | Swing: "+SMC_BiasText(swingBias)+
                   " | Internal: "+SMC_BiasText(internalBias));
}

void SMC_DrawHorizontalStructure(const SMC_DrawConfig &config,
                             StructureDisplayState &latestStructures[],
                             bool &presentStructuresDirty,const string id,
                             const PivotState &pivot,
                             const datetime rightTime,const string tag,
                             const color lineColor,const bool internal,
                             const bool bullish,const ENUM_SMC_SIZE labelSize)
{
   int slot=(internal ? 0 : 2)+(bullish ? 0 : 1);
   if(latestStructures[slot].valid && latestStructures[slot].id!=id)
   {
      ObjectDelete(0,config.objectPrefix+"STR_Line_"+
                     latestStructures[slot].id);
      ObjectDelete(0,config.objectPrefix+"STR_Label_"+
                     latestStructures[slot].id);
   }
   latestStructures[slot].pivot=pivot;
   latestStructures[slot].rightTime=rightTime;
   latestStructures[slot].id=id;
   latestStructures[slot].tag=tag;
   latestStructures[slot].lineColor=lineColor;
   latestStructures[slot].internal=internal;
   latestStructures[slot].bullish=bullish;
   latestStructures[slot].labelSize=labelSize;
   latestStructures[slot].valid=true;
   presentStructuresDirty=true;
}

void SMC_RenderPresentStructures(const SMC_DrawConfig &config,
                             const StructureDisplayState &latestStructures[],
                             bool &presentStructuresDirty)
{
   if(!presentStructuresDirty)
      return;
   for(int i=0;i<ArraySize(latestStructures);i++)
   {
      if(!latestStructures[i].valid)
         continue;
      string lineName=config.objectPrefix+"STR_Line_"+latestStructures[i].id;
      string labelName=config.objectPrefix+"STR_Label_"+latestStructures[i].id;
      PivotState pivot=latestStructures[i].pivot;
      datetime rightTime=latestStructures[i].rightTime;
      if(ObjectFind(0,lineName)<0)
      {
         if(!ObjectCreate(0,lineName,OBJ_TREND,0,pivot.time,pivot.current,
                          rightTime,pivot.current))
            continue;
      }
      else
      {
         SMC_MoveObjectPointIfChanged(lineName,0,pivot.time,pivot.current);
         SMC_MoveObjectPointIfChanged(lineName,1,rightTime,pivot.current);
      }
      ObjectSetInteger(0,lineName,OBJPROP_COLOR,latestStructures[i].lineColor);
      ObjectSetInteger(0,lineName,OBJPROP_STYLE,
                       latestStructures[i].internal ? STYLE_DASH : STYLE_SOLID);
      ObjectSetInteger(0,lineName,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,lineName,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(0,lineName,OBJPROP_SELECTABLE,false);
      datetime middle=pivot.time+(rightTime-pivot.time)/2;
      SMC_DrawText(labelName,middle,pivot.current,
               SMC_TimeframeLabel(config.chartTimeframe)+" "+
               latestStructures[i].tag,
               latestStructures[i].lineColor,
               latestStructures[i].bullish ? ANCHOR_UPPER : ANCHOR_LOWER,
               (int)latestStructures[i].labelSize);
   }
   presentStructuresDirty=false;
}

void SMC_ExtendPresentStructures(const SMC_DrawConfig &config,
                             StructureDisplayState &latestStructures[],
                             const bool presentStructuresDirty,
                             const datetime rightTime)
{
   if(presentStructuresDirty)
      return;
   for(int i=0;i<ArraySize(latestStructures);i++)
   {
      if(!latestStructures[i].valid)
         continue;
      latestStructures[i].rightTime=rightTime;
      string lineName=config.objectPrefix+"STR_Line_"+latestStructures[i].id;
      string labelName=config.objectPrefix+"STR_Label_"+latestStructures[i].id;
      PivotState pivot=latestStructures[i].pivot;
      if(ObjectFind(0,lineName)>=0)
      {
         SMC_MoveObjectPointIfChanged(lineName,0,pivot.time,pivot.current);
         SMC_MoveObjectPointIfChanged(lineName,1,rightTime,pivot.current);
      }
      if(ObjectFind(0,labelName)>=0)
      {
         datetime middle=pivot.time+(rightTime-pivot.time)/2;
         SMC_MoveObjectPointIfChanged(labelName,0,middle,pivot.current);
      }
   }
}

bool SMC_IsStructureVisible(const SMC_DrawConfig &config,const bool internal,
                            const bool bullish,const string tag)
{
   if(internal && !config.showInternalStructure) return false;
   if(!internal && !config.showSwingStructure) return false;
   ENUM_SMC_SHOW filter;
   if(internal)
      filter=bullish ? config.internalBullishStructure :
                       config.internalBearishStructure;
   else
      filter=bullish ? config.swingBullishStructure :
                       config.swingBearishStructure;
   if(filter==SMC_ALL) return true;
   if(filter==SMC_BOS) return tag=="BOS";
   return tag=="CHoCH";
}

#endif // SMC_DRAWSTRUCTURE_MQH
