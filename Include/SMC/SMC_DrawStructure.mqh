// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWSTRUCTURE_MQH
#define SMC_DRAWSTRUCTURE_MQH

#include <SMC/SMC_DrawHelpers.mqh>

void SMC_DrawHorizontalStructure(const SMC_DrawConfig &config,
                             StructureDisplayState &latestStructures[],
                             bool &presentStructuresDirty,const string id,
                             const PivotState &pivot,
                             const datetime rightTime,const string tag,
                             const color lineColor,const bool internal,
                             const bool bullish,const ENUM_SMC_SIZE labelSize)
{
   if(config.mode==SMC_HISTORICAL)
   {
      string lineName=config.objectPrefix+"STR_Line_"+id;
      string labelName=config.objectPrefix+"STR_Label_"+id;
      SMC_PineLineSet(lineName,pivot.time,pivot.current,rightTime,
                      pivot.current,lineColor,
                      internal ? STYLE_DASH : STYLE_SOLID,
                      1,false,false,false,20);
      datetime middle=pivot.time+(rightTime-pivot.time)/2;
      SMC_DrawText(labelName,middle,pivot.current,
                   SMC_TimeframeLabel(config.chartTimeframe)+" "+tag,
                   lineColor,bullish ? ANCHOR_UPPER : ANCHOR_LOWER,
                   (int)labelSize);
      return;
   }
   int slot=(internal ? 0 : 2)+(bullish ? 0 : 1);
   if(latestStructures[slot].valid && latestStructures[slot].id!=id)
   {
      SMC_PineDrawingDelete(config.objectPrefix+"STR_Line_"+
                            latestStructures[slot].id);
      SMC_PineDrawingDelete(config.objectPrefix+"STR_Label_"+
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
   if(config.mode!=SMC_PRESENT)
      return;
   if(!presentStructuresDirty)
      return;
   int count=MathMin(ArraySize(latestStructures),4);
   bool rendered[4];
   for(int i=0;i<count;i++)
      rendered[i]=false;
   for(int rank=0;rank<count;rank++)
   {
      int oldest=-1;
      for(int i=0;i<count;i++)
      {
         if(rendered[i] || !latestStructures[i].valid)
            continue;
         if(oldest<0 ||
            latestStructures[i].pivot.time<latestStructures[oldest].pivot.time)
            oldest=i;
      }
      if(oldest<0)
         break;
      rendered[oldest]=true;
      string lineName=config.objectPrefix+"STR_Line_"+latestStructures[oldest].id;
      string labelName=config.objectPrefix+"STR_Label_"+latestStructures[oldest].id;
      PivotState pivot=latestStructures[oldest].pivot;
      datetime rightTime=latestStructures[oldest].rightTime;
      SMC_PineLineSet(lineName,pivot.time,pivot.current,rightTime,
                      pivot.current,latestStructures[oldest].lineColor,
                      latestStructures[oldest].internal ? STYLE_DASH :
                                                         STYLE_SOLID,
                      1,false,false,true,20);
      datetime middle=pivot.time+(rightTime-pivot.time)/2;
      SMC_DrawText(labelName,middle,pivot.current,
                   SMC_TimeframeLabel(config.chartTimeframe)+" "+
                   latestStructures[oldest].tag,
                   latestStructures[oldest].lineColor,
                   latestStructures[oldest].bullish ? ANCHOR_UPPER : ANCHOR_LOWER,
                   (int)latestStructures[oldest].labelSize,true);
   }
   presentStructuresDirty=false;
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
