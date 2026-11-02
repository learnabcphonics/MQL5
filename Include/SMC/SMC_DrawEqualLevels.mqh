// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWEQUALLEVELS_MQH
#define SMC_DRAWEQUALLEVELS_MQH

#include <SMC/SMC_DrawHelpers.mqh>

void SMC_DrawEqualLevelEvent(const SMC_DrawConfig &config,
                             const EqualLevelEvent &event,
                             const color lineColor,
                             const ENUM_SMC_SIZE labelSize)
{
   if(!event.valid)
      return;
   string kind=(event.high ? "EQH" : "EQL");
   string id=(config.mode==SMC_HISTORICAL ?
              IntegerToString((int)event.secondTime) : "Current");
   string lineName=config.objectPrefix+kind+"_Line_"+id;
   string labelName=config.objectPrefix+kind+"_Label_"+id;
   SMC_PineLineSet(lineName,event.firstTime,event.firstPrice,
                   event.secondTime,event.secondPrice,lineColor,STYLE_DOT,
                   1,false,false,false,20);
   SMC_DrawText(labelName,event.labelTime,event.secondPrice,
                SMC_TimeframeLabel(config.chartTimeframe)+" "+kind,
                lineColor,event.high ? ANCHOR_LOWER : ANCHOR_UPPER,
                (int)labelSize);
}

#endif // SMC_DRAWEQUALLEVELS_MQH
