// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_PANEL_MQH
#define SMC_PANEL_MQH

#include <SMC/SMC_Types.mqh>

enum ENUM_SMC_PANEL_GROUP
{
   SMC_PANEL_NONE,
   SMC_PANEL_STRUCTURE,
   SMC_PANEL_ORDER_BLOCKS,
   SMC_PANEL_FVG,
   SMC_PANEL_PREVIOUS_LEVELS,
   SMC_PANEL_STRONG_WEAK
};

struct SMC_PanelState
{
   bool structures;
   bool orderBlocks;
   bool fairValueGaps;
   bool previousLevels;
   bool strongWeak;
};

bool SMC_PanelCreateButton(const string name,const string text,
                           const int y,const bool enabled,const color onColor)
{
   if(ObjectFind(0,name)<0 && !ObjectCreate(0,name,OBJ_BUTTON,0,0,0))
   {
      PrintFormat("SMC: unable to create panel button %s (error=%d).",
                  name,GetLastError());
      return false;
   }
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,10);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,124);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,22);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,enabled ? onColor : clrDimGray);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,clrGray);
   ObjectSetInteger(0,name,OBJPROP_STATE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,100);
   ObjectSetString(0,name,OBJPROP_TEXT,text+(enabled ? " ON" : " OFF"));
   ObjectSetString(0,name,OBJPROP_TOOLTIP,
                   "Toggle "+text+" display. Analysis logic is unchanged.");
   return true;
}

bool SMC_PanelDraw(const string prefix,const SMC_PanelState &state)
{
   string background=prefix+"Background";
   if(ObjectFind(0,background)<0 &&
      !ObjectCreate(0,background,OBJ_RECTANGLE_LABEL,0,0,0))
   {
      PrintFormat("SMC: unable to create panel background (error=%d).",
                  GetLastError());
      return false;
   }
   ObjectSetInteger(0,background,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,background,OBJPROP_XDISTANCE,6);
   ObjectSetInteger(0,background,OBJPROP_YDISTANCE,6);
   ObjectSetInteger(0,background,OBJPROP_XSIZE,132);
   ObjectSetInteger(0,background,OBJPROP_YSIZE,158);
   ObjectSetInteger(0,background,OBJPROP_BGCOLOR,C'20,24,32');
   ObjectSetInteger(0,background,OBJPROP_BORDER_COLOR,C'75,82,95');
   ObjectSetInteger(0,background,OBJPROP_BACK,false);
   ObjectSetInteger(0,background,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,background,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,background,OBJPROP_ZORDER,0);

   string title=prefix+"Title";
   if(ObjectFind(0,title)<0 && !ObjectCreate(0,title,OBJ_LABEL,0,0,0))
   {
      PrintFormat("SMC: unable to create panel title (error=%d).",GetLastError());
      return false;
   }
   ObjectSetInteger(0,title,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,title,OBJPROP_XDISTANCE,12);
   ObjectSetInteger(0,title,OBJPROP_YDISTANCE,12);
   ObjectSetInteger(0,title,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,title,OBJPROP_FONTSIZE,9);
   ObjectSetInteger(0,title,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,title,OBJPROP_HIDDEN,true);
   ObjectSetString(0,title,OBJPROP_TEXT,"SMC DISPLAY");

   bool created=true;
   created=SMC_PanelCreateButton(prefix+"Structure","Structure",30,
                                 state.structures,C'35,117,76') && created;
   created=SMC_PanelCreateButton(prefix+"OrderBlocks","OB",56,
                                 state.orderBlocks,C'49,121,245') && created;
   created=SMC_PanelCreateButton(prefix+"FVG","FVG",82,
                                 state.fairValueGaps,C'0,150,110') && created;
   created=SMC_PanelCreateButton(prefix+"PreviousLevels","Levels",108,
                                 state.previousLevels,C'33,87,243') && created;
   created=SMC_PanelCreateButton(prefix+"StrongWeak","Strong/Weak",134,
                                 state.strongWeak,C'160,95,35') && created;
   return created;
}

void SMC_PanelDelete(const string prefix)
{
   ObjectDelete(0,prefix+"Background");
   ObjectDelete(0,prefix+"Title");
   ObjectDelete(0,prefix+"Structure");
   ObjectDelete(0,prefix+"OrderBlocks");
   ObjectDelete(0,prefix+"FVG");
   ObjectDelete(0,prefix+"PreviousLevels");
   ObjectDelete(0,prefix+"StrongWeak");
}

ENUM_SMC_PANEL_GROUP SMC_PanelHandleClick(const string prefix,
                                          const string objectName,
                                          SMC_PanelState &state)
{
   if(objectName==prefix+"Structure")
   {
      state.structures=!state.structures;
      return SMC_PANEL_STRUCTURE;
   }
   if(objectName==prefix+"OrderBlocks")
   {
      state.orderBlocks=!state.orderBlocks;
      return SMC_PANEL_ORDER_BLOCKS;
   }
   if(objectName==prefix+"FVG")
   {
      state.fairValueGaps=!state.fairValueGaps;
      return SMC_PANEL_FVG;
   }
   if(objectName==prefix+"PreviousLevels")
   {
      state.previousLevels=!state.previousLevels;
      return SMC_PANEL_PREVIOUS_LEVELS;
   }
   if(objectName==prefix+"StrongWeak")
   {
      state.strongWeak=!state.strongWeak;
      return SMC_PANEL_STRONG_WEAK;
   }
   return SMC_PANEL_NONE;
}

#endif // SMC_PANEL_MQH
