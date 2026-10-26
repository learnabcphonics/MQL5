// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#property copyright " Smart Money Concepts"
#property version   "1.00"
#property strict
#property indicator_chart_window
#include <SMC/SMC_Types.mqh>
#include <SMC/SMC_Engine.mqh>
#include <SMC/SMC_Panel.mqh>
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_label1  "SMC trend candles"
#property indicator_color1  clrMediumSeaGreen,clrIndianRed

input group "Smart Money Concepts"
input ENUM_SMC_STYLE Style = SMC_COLORED;
input bool ColorCandles = false;
input int MaxBarsToProcess = 2000;

input group "Chart Display"
input bool HideTradeHistoryMarkers = true;
input bool ShowControlPanel = true;

input group "Market Bias"
input bool ShowMarketBias = true;

input group "Alerts"
input bool AlertInternalBullishBOS = false;
input bool AlertInternalBullishCHoCH = false;
input bool AlertInternalBearishBOS = false;
input bool AlertInternalBearishCHoCH = false;
input bool AlertSwingBullishBOS = false;
input bool AlertSwingBullishCHoCH = false;
input bool AlertSwingBearishBOS = false;
input bool AlertSwingBearishCHoCH = false;
input bool AlertInternalBullishOrderBlock = false;
input bool AlertInternalBearishOrderBlock = false;
input bool AlertSwingBullishOrderBlock = false;
input bool AlertSwingBearishOrderBlock = false;
input bool AlertEqualHighs = false;
input bool AlertEqualLows = false;
input bool AlertBullishFVG = false;
input bool AlertBearishFVG = false;

input group "Real Time Internal Structure"
input bool ShowInternalStructure = true;
input ENUM_SMC_SHOW InternalBullishStructure = SMC_ALL;
input color InternalBullishColor = C'8,153,129';
input ENUM_SMC_SHOW InternalBearishStructure = SMC_ALL;
input color InternalBearishColor = C'242,54,69';
input bool InternalConfluenceFilter = false;
input ENUM_SMC_SIZE InternalLabelSize = SMC_TINY;

input group "Real Time Swing Structure"
input bool ShowSwingStructure = true;
input ENUM_SMC_SHOW SwingBullishStructure = SMC_ALL;
input color SwingBullishColor = C'8,153,129';
input ENUM_SMC_SHOW SwingBearishStructure = SMC_ALL;
input color SwingBearishColor = C'242,54,69';
input ENUM_SMC_SIZE SwingLabelSize = SMC_SMALL;
input bool ShowSwingPoints = false;
input int SwingLength = 50;
input bool ShowStrongWeakHighLow = true;

input group "Order Blocks"
input bool ShowInternalOrderBlocks = true;
input int InternalOrderBlocksToShow = 3;
input bool ShowSwingOrderBlocks = false;
input int SwingOrderBlocksToShow = 5;
input int OrderBlockExtend = 20;
input ENUM_SMC_FILTER OrderBlockFilter = SMC_ATR;
input ENUM_SMC_MITIGATION OrderBlockMitigation = SMC_HIGH_LOW;
input color InternalBullishOBColor = C'49,121,245';
input color InternalBearishOBColor = C'247,124,128';
input color SwingBullishOBColor = C'24,72,204';
input color SwingBearishOBColor = C'178,40,51';

input group "EQH/EQL"
input bool ShowEqualHighsLows = true;
input int EqualHighLowConfirmationBars = 3;
input double EqualHighLowThreshold = 0.1;
input ENUM_SMC_SIZE EqualHighLowLabelSize = SMC_TINY;

input group "Fair Value Gaps"
input bool ShowFairValueGaps = false;
input bool FairValueGapAutoThreshold = false;
input color BullishFVGColor = C'0,255,104';
input color BearishFVGColor = C'255,0,8';
input int FairValueGapExtend = 1;
input int MaxFairValueGapsToShow = 5;

input group "Previous Period Highs & Lows"
input bool ShowDailyLevels = false;
input ENUM_SMC_LINE_STYLE DailyLevelsStyle = SMC_SOLID;
input color DailyLevelsColor = C'33,87,243';
input bool ShowWeeklyLevels = false;
input ENUM_SMC_LINE_STYLE WeeklyLevelsStyle = SMC_SOLID;
input color WeeklyLevelsColor = C'33,87,243';
input bool ShowMonthlyLevels = false;
input ENUM_SMC_LINE_STYLE MonthlyLevelsStyle = SMC_SOLID;
input color MonthlyLevelsColor = C'33,87,243';

input group "Premium & Discount Zones"
input bool ShowPremiumDiscountZones = false;
input color PremiumZoneColor = C'242,54,69';
input color EquilibriumZoneColor = C'135,139,148';
input color DiscountZoneColor = C'8,153,129';

double CandleOpen[], CandleHigh[], CandleLow[], CandleClose[], CandleColorIndex[];
double ParsedHighs[], ParsedLows[], AtrCache[], MeanRangeCache[], TrueRangeCache[];
string ObjectPrefix = "SMC_";
string PanelObjectPrefix = "SMC_Panel_";
SMC_DrawConfig DrawConfig;
SMC_PanelState PanelState;
datetime LastProcessedBar = 0;
int LastRatesTotal = 0;
bool AlertsArmed = false;
bool PreviousTradeHistoryVisibility = false;
bool TradeHistoryVisibilityCaptured = false;
bool TradeHistoryVisibilityChanged = false;
bool RuntimeShowInternalStructure = true;
bool RuntimeShowSwingStructure = true;
bool RuntimeShowInternalOrderBlocks = true;
bool RuntimeShowSwingOrderBlocks = true;
bool RuntimeShowFairValueGaps = true;
bool RuntimeShowDailyLevels = false;
bool RuntimeShowWeeklyLevels = false;
bool RuntimeShowMonthlyLevels = false;
bool RuntimeShowStrongWeakHighLow = true;

PivotState SwingHigh, SwingLow, InternalHigh, InternalLow, EqualHigh, EqualLow;
PivotState TrailingTop, TrailingBottom;
datetime TrailingAnchorTime=0;
StructureDisplayState LatestStructures[4];
bool PresentStructuresDirty = false;
int SwingBias = 0, InternalBias = 0;
int SwingLeg = 0, InternalLeg = 0, EqualLeg = 0;
OrderBlockState OrderBlocks[];
FairValueGapState FairValueGaps[];
double CurrentFVGThreshold=0.0;
double CumulativeRangeClosedSum=0.0;
datetime LastFVGUpdateBarTime=0;
double LastFVGUpdateHigh=0.0;
double LastFVGUpdateLow=0.0;
bool FVGUpdateStateInitialized=false;

color BullColor(const bool internal)
{
   if(Style == SMC_MONOCHROME)
      return C'178,181,190';
   return internal ? InternalBullishColor : SwingBullishColor;
}

color BearColor(const bool internal)
{
   if(Style == SMC_MONOCHROME)
      return C'93,96,107';
   return internal ? InternalBearishColor : SwingBearishColor;
}

void ConfigureDrawing()
{
   DrawConfig.objectPrefix=ObjectPrefix;
   DrawConfig.symbol=_Symbol;
   DrawConfig.chartTimeframe=_Period;
   DrawConfig.style=Style;
   DrawConfig.showMarketBias=ShowMarketBias;
   DrawConfig.showInternalStructure=RuntimeShowInternalStructure;
   DrawConfig.showSwingStructure=RuntimeShowSwingStructure;
   DrawConfig.internalBullishStructure=InternalBullishStructure;
   DrawConfig.internalBearishStructure=InternalBearishStructure;
   DrawConfig.swingBullishStructure=SwingBullishStructure;
   DrawConfig.swingBearishStructure=SwingBearishStructure;
   DrawConfig.internalBullishColor=InternalBullishColor;
   DrawConfig.internalBearishColor=InternalBearishColor;
   DrawConfig.swingBullishColor=SwingBullishColor;
   DrawConfig.swingBearishColor=SwingBearishColor;
   DrawConfig.showInternalOrderBlocks=RuntimeShowInternalOrderBlocks;
   DrawConfig.showSwingOrderBlocks=RuntimeShowSwingOrderBlocks;
   DrawConfig.internalOrderBlocksToShow=InternalOrderBlocksToShow;
   DrawConfig.swingOrderBlocksToShow=SwingOrderBlocksToShow;
   DrawConfig.orderBlockExtend=OrderBlockExtend;
   DrawConfig.internalBullishOBColor=InternalBullishOBColor;
   DrawConfig.internalBearishOBColor=InternalBearishOBColor;
   DrawConfig.swingBullishOBColor=SwingBullishOBColor;
   DrawConfig.swingBearishOBColor=SwingBearishOBColor;
   DrawConfig.showSwingPoints=ShowSwingPoints;
   DrawConfig.swingLength=SwingLength;
   DrawConfig.showStrongWeakHighLow=RuntimeShowStrongWeakHighLow;
   DrawConfig.showPremiumDiscountZones=ShowPremiumDiscountZones;
   DrawConfig.premiumZoneColor=PremiumZoneColor;
   DrawConfig.equilibriumZoneColor=EquilibriumZoneColor;
   DrawConfig.discountZoneColor=DiscountZoneColor;
   DrawConfig.showDailyLevels=RuntimeShowDailyLevels;
   DrawConfig.showWeeklyLevels=RuntimeShowWeeklyLevels;
   DrawConfig.showMonthlyLevels=RuntimeShowMonthlyLevels;
   DrawConfig.dailyLevelsStyle=DailyLevelsStyle;
   DrawConfig.weeklyLevelsStyle=WeeklyLevelsStyle;
   DrawConfig.monthlyLevelsStyle=MonthlyLevelsStyle;
   DrawConfig.dailyLevelsColor=DailyLevelsColor;
   DrawConfig.weeklyLevelsColor=WeeklyLevelsColor;
   DrawConfig.monthlyLevelsColor=MonthlyLevelsColor;
}

#include <SMC/SMC_Draw.mqh>


void SendPopupAlert(const bool enabled,const string eventName)
{
   if(enabled && AlertsArmed)
      Alert("SMC: ",eventName," on ",_Symbol," ",EnumToString(_Period));
}

void RemoveMitigatedOrderBlocks(const double high,const double low,const double close,
                               const datetime barTime,const bool allowAlert)
{
   OrderBlockState removed[];
   int removedCount=0;
   if(!SMC_RemoveMitigatedOrderBlocks(high,low,close,barTime,
                                      OrderBlockMitigation,OrderBlocks,
                                      removed,removedCount))
   {
      Print("SMC: order block mitigation analysis failed.");
      return;
   }
   for(int i=0;i<removedCount;i++)
   {
      string objectName=SMC_OrderBlockObjectName(DrawConfig,removed[i]);
      ObjectDelete(0,objectName);
      ObjectDelete(0,objectName+"_Label");
      ObjectDelete(0,objectName+"_Origin");
      if(!allowAlert)
         continue;
      string scope=(removed[i].internal ? "Internal " : "Swing ");
      bool bullish=(removed[i].bias>0);
      bool enabled=(removed[i].internal ?
                    (bullish ? AlertInternalBullishOrderBlock :
                               AlertInternalBearishOrderBlock) :
                    (bullish ? AlertSwingBullishOrderBlock :
                               AlertSwingBearishOrderBlock));
      SendPopupAlert(enabled,(bullish ? "Bullish " : "Bearish ")+scope+
                             "order block breakout");
   }
}

void RenderStructureEvents(const StructureEvent &events[],const int eventCount)
{
   datetime rightTime=0;
   for(int i=0;i<eventCount;i++)
   {
      StructureEvent event=events[i];
      string direction=(event.bullish ? "Bullish " : "Bearish ");
      string scope=(event.internal ? "Internal " : "Swing ");
      if(event.liveBar)
      {
         bool enabled;
         if(event.internal)
            enabled=(event.bullish ?
                     (event.tag=="BOS" ? AlertInternalBullishBOS : AlertInternalBullishCHoCH) :
                     (event.tag=="BOS" ? AlertInternalBearishBOS : AlertInternalBearishCHoCH));
         else
            enabled=(event.bullish ?
                     (event.tag=="BOS" ? AlertSwingBullishBOS : AlertSwingBullishCHoCH) :
                     (event.tag=="BOS" ? AlertSwingBearishBOS : AlertSwingBearishCHoCH));
         SendPopupAlert(enabled,scope+direction+event.tag);
      }
      if(!IsStructureVisible(DrawConfig,event.internal,event.bullish,event.tag))
         continue;
      if(rightTime==0)
         rightTime=event.time+PeriodSeconds(_Period);
      color lineColor=(event.bullish ?
                       SMC_DrawBullColor(DrawConfig,event.internal) :
                       SMC_DrawBearColor(DrawConfig,event.internal));
      string id=(event.internal ? "I_" : "S_")+
                IntegerToString((int)event.time);
      DrawHorizontalStructure(DrawConfig,LatestStructures,
                              PresentStructuresDirty,id,event.pivot,rightTime,
                              event.tag,lineColor,event.internal,event.bullish,
                              event.labelSize);
   }
}

void DetectEqualHighLow(const int size,int &legState,
                        PivotState &equalHigh,PivotState &equalLow,
                        const int i,const int ratesTotal,const datetime &time[],
                        const double &high[],const double &low[],const double &atr[])
{
   EqualLevelEvent event;
   SMC_DetectEqualHighLow(size,legState,equalHigh,equalLow,i,ratesTotal,time,
                          high,low,atr,EqualHighLowThreshold,event);
   if(!event.valid)
      return;
   bool enabled=(event.high ? AlertEqualHighs : AlertEqualLows);
   if(ShowEqualHighsLows)
      DrawEqualLevelEvent(DrawConfig,event,
                          event.high ? BearColor(false) : BullColor(false),
                          EqualHighLowLabelSize);
   if(event.liveBar)
      SendPopupAlert(enabled,event.high ? "Equal highs detected" :
                                         "Equal lows detected");
}

void DrawActiveFairValueGaps(const MqlRates &bars[])
{
   if(!RuntimeShowFairValueGaps || ArraySize(bars)==0)
      return;
   int gapCount=ArraySize(FairValueGaps);
   bool selected[];
   if(ArrayResize(selected,gapCount)!=gapCount)
   {
      PrintFormat("SMC: unable to allocate FVG display selection (error=%d).",
                  GetLastError());
      return;
   }
   for(int i=0;i<gapCount;i++)
      selected[i]=false;

   int displayCount=MathMin(MaxFairValueGapsToShow,gapCount);
   for(int rank=0;rank<displayCount;rank++)
   {
      int newest=-1;
      for(int i=0;i<gapCount;i++)
      {
         if(selected[i])
            continue;
         if(newest<0 || FairValueGaps[i].time>FairValueGaps[newest].time)
            newest=i;
      }
      if(newest>=0)
         selected[newest]=true;
   }

   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0)
      periodSeconds=60;
   datetime right=bars[0].time+FairValueGapExtend*periodSeconds;
   for(int i=0;i<gapCount;i++)
   {
      FairValueGapState gap=FairValueGaps[i];
      if(!selected[i])
      {
         DeleteFairValueGap(DrawConfig,gap);
         continue;
      }
      gap.right=right;
      color gapColor=(gap.bias>0 ? BullishFVGColor : BearishFVGColor);
      DrawFairValueGap(DrawConfig,gap,SMC_DrawWithAlpha(gapColor,77));
   }
}

void UpdateFairValueGapsOnTick(const datetime chartBarTime,
                               const double currentHigh,const double currentLow)
{
   if(FVGUpdateStateInitialized && LastFVGUpdateBarTime==chartBarTime &&
      LastFVGUpdateHigh==currentHigh && LastFVGUpdateLow==currentLow)
      return;
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int copied=CopyRates(_Symbol,_Period,0,4,bars);
   if(copied<4)
   {
      PrintFormat("SMC: unable to update FVG history for chart timeframe %s (bars=%d, error=%d).",
                  EnumToString(_Period),copied,GetLastError());
      return;
   }
   FairValueGapState removed[],added[];
   int removedCount=0,addedCount=0;
   if(!SMC_UpdateFairValueGaps(bars,chartBarTime,PeriodSeconds(_Period),
                               FairValueGapExtend,CurrentFVGThreshold,
                               FairValueGapAutoThreshold,_Point,FairValueGaps,
                               removed,removedCount,added,addedCount))
   {
      Print("SMC: failed to update fair value gap analysis.");
      return;
   }
   for(int i=0;i<removedCount;i++)
      DeleteFairValueGap(DrawConfig,removed[i]);
   for(int i=0;i<addedCount;i++)
   {
      SendPopupAlert(added[i].bias>0 ? AlertBullishFVG : AlertBearishFVG,
                     added[i].bias>0 ? "Bullish fair value gap" :
                                       "Bearish fair value gap");
   }
   DrawActiveFairValueGaps(bars);
   LastFVGUpdateBarTime=chartBarTime;
   LastFVGUpdateHigh=currentHigh;
   LastFVGUpdateLow=currentLow;
   FVGUpdateStateInitialized=true;
}

bool RefreshCurrentFVGThreshold()
{
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int copied=CopyRates(_Symbol,_Period,0,MaxBarsToProcess,bars);
   if(copied<3)
   {
      PrintFormat("SMC: unable to refresh FVG threshold for chart timeframe %s (bars=%d, error=%d).",
                  EnumToString(_Period),copied,GetLastError());
      return false;
   }
   return SMC_UpdateFVGThreshold(bars,_Point,CurrentFVGThreshold);
}

void DrawFVGs()
{
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int copied=CopyRates(_Symbol,_Period,0,MaxBarsToProcess,bars);
   if(copied<3)
   {
      PrintFormat("SMC: unable to load FVG history for chart timeframe %s (bars=%d, error=%d).",
                  EnumToString(_Period),copied,GetLastError());
      return;
   }
   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0)
      periodSeconds=60;
   if(!SMC_AnalyzeHistoricalFVG(bars,FairValueGapAutoThreshold,
                                FairValueGapExtend,periodSeconds,_Point,
                                CurrentFVGThreshold,FairValueGaps))
   {
      Print("SMC: failed to analyze historical fair value gaps.");
      return;
   }
   PrintFormat("SMC: FVG scan complete (timeframe=%s, bars=%d, auto_threshold=%s, active_unmitigated=%d).",
               EnumToString(_Period),copied,
               (FairValueGapAutoThreshold ? "true" : "false"),
               ArraySize(FairValueGaps));
   if(RuntimeShowFairValueGaps)
      DrawActiveFairValueGaps(bars);
}

void UpdateTrailingLevelsOnTick(const datetime currentTime,const double currentHigh,
                                const double currentLow,const int periodSeconds)
{
   double previousTop=TrailingTop.current;
   datetime previousTopTime=TrailingTop.time;
   double previousBottom=TrailingBottom.current;
   datetime previousBottomTime=TrailingBottom.time;
   bool hadTrailingTop=TrailingTop.initialized;
   bool hadTrailingBottom=TrailingBottom.initialized;
   SMC_UpdateTrailingLevels(true,currentTime,currentHigh,currentLow,
                            TrailingTop,TrailingBottom);
   bool levelsChanged=hadTrailingTop!=TrailingTop.initialized ||
                      hadTrailingBottom!=TrailingBottom.initialized ||
                      previousTop!=TrailingTop.current ||
                      previousTopTime!=TrailingTop.time ||
                      previousBottom!=TrailingBottom.current ||
                      previousBottomTime!=TrailingBottom.time;
   if(!levelsChanged)
      return;
   SMC_DrawUpdateTrailingLevels(DrawConfig,TrailingTop,TrailingBottom,SwingBias,
                                TrailingAnchorTime,currentTime,periodSeconds);
}

void HidePanelGroupObjects(const ENUM_SMC_PANEL_GROUP group)
{
   if(group==SMC_PANEL_STRUCTURE)
   {
      DeleteObjectsWithPrefix(ObjectPrefix+"StructureLine_");
      DeleteObjectsWithPrefix(ObjectPrefix+"StructureLabel_");
   }
   else if(group==SMC_PANEL_ORDER_BLOCKS)
      DeleteObjectsWithPrefix(ObjectPrefix+"OB_");
   else if(group==SMC_PANEL_FVG)
      DeleteObjectsWithPrefix(ObjectPrefix+"FVG_");
   else if(group==SMC_PANEL_PREVIOUS_LEVELS)
   {
      string levels[12]={"D H","D L","D H_Label","D L_Label",
                         "W H","W L","W H_Label","W L_Label",
                         "M H","M L","M H_Label","M L_Label"};
      for(int i=0;i<ArraySize(levels);i++)
      {
         string name=levels[i];
         StringReplace(name," ","");
         ObjectDelete(0,ObjectPrefix+name);
      }
   }
   else if(group==SMC_PANEL_STRONG_WEAK)
   {
      ObjectDelete(0,ObjectPrefix+"StrongWeak_High");
      ObjectDelete(0,ObjectPrefix+"StrongWeak_Low");
      ObjectDelete(0,ObjectPrefix+"StrongWeak_High_Label");
      ObjectDelete(0,ObjectPrefix+"StrongWeak_Low_Label");
   }
}

void ResetState()
{
   ZeroMemory(SwingHigh); ZeroMemory(SwingLow);
   ZeroMemory(InternalHigh); ZeroMemory(InternalLow);
   ZeroMemory(EqualHigh); ZeroMemory(EqualLow);
   ZeroMemory(TrailingTop); ZeroMemory(TrailingBottom);
   TrailingAnchorTime=0;
   SwingBias=0; InternalBias=0;
   SwingLeg=0; InternalLeg=0;    EqualLeg=0;
   for(int i=0;i<ArraySize(LatestStructures);i++)
   {
      LatestStructures[i].valid=false;
      LatestStructures[i].id="";
      LatestStructures[i].tag="";
   }
   PresentStructuresDirty=false;
   ArrayResize(OrderBlocks,0);
   ArrayResize(FairValueGaps,0);
   CurrentFVGThreshold=0.0;
   CumulativeRangeClosedSum=0.0;
   LastFVGUpdateBarTime=0;
   LastFVGUpdateHigh=0.0;
   LastFVGUpdateLow=0.0;
   FVGUpdateStateInitialized=false;
}

int OnInit()
{
   if(SwingLength<10 || MaxBarsToProcess<MathMax(SwingLength,EqualHighLowConfirmationBars)+3 ||
      MaxBarsToProcess>10000 || EqualHighLowConfirmationBars<1 ||
      InternalOrderBlocksToShow<1 || InternalOrderBlocksToShow>20 ||
      SwingOrderBlocksToShow<1 || SwingOrderBlocksToShow>20 ||
      OrderBlockExtend<1 || OrderBlockExtend>1000 ||
      FairValueGapExtend<0 || MaxFairValueGapsToShow<1 ||
      MaxFairValueGapsToShow>100 || EqualHighLowThreshold<0.0 ||
      EqualHighLowThreshold>0.5)
      return INIT_PARAMETERS_INCORRECT;
   RuntimeShowInternalStructure=ShowInternalStructure;
   RuntimeShowSwingStructure=ShowSwingStructure;
   RuntimeShowInternalOrderBlocks=ShowInternalOrderBlocks;
   RuntimeShowSwingOrderBlocks=ShowSwingOrderBlocks;
   RuntimeShowFairValueGaps=ShowFairValueGaps;
   RuntimeShowDailyLevels=ShowDailyLevels;
   RuntimeShowWeeklyLevels=ShowWeeklyLevels;
   RuntimeShowMonthlyLevels=ShowMonthlyLevels;
   RuntimeShowStrongWeakHighLow=ShowStrongWeakHighLow;
   PanelState.structures=(ShowInternalStructure || ShowSwingStructure);
   PanelState.orderBlocks=(ShowInternalOrderBlocks || ShowSwingOrderBlocks);
   PanelState.fairValueGaps=ShowFairValueGaps;
   PanelState.previousLevels=(ShowDailyLevels || ShowWeeklyLevels ||
                              ShowMonthlyLevels);
   PanelState.strongWeak=ShowStrongWeakHighLow;
   string legacyObjectPrefix="SC"+
                             IntegerToString((int)(ChartID()%100000))+"_";
   DeleteObjectsWithPrefix(legacyObjectPrefix);
   ObjectPrefix="SMC"+IntegerToString((long)ChartID())+"_";
   PanelObjectPrefix="SMCPanel"+IntegerToString((long)ChartID())+"_";
   DeleteSMCObjects(ObjectPrefix);
   SMC_PanelDelete(PanelObjectPrefix);
   long tradeHistoryVisible=0;
   TradeHistoryVisibilityCaptured=
      ChartGetInteger(0,CHART_SHOW_TRADE_HISTORY,0,tradeHistoryVisible);
   if(!TradeHistoryVisibilityCaptured)
      PrintFormat("SMC: unable to read trade-history chart setting (error=%d).",
                  GetLastError());
   else
   {
      PreviousTradeHistoryVisibility=(tradeHistoryVisible!=0);
      if(HideTradeHistoryMarkers && PreviousTradeHistoryVisibility)
      {
         TradeHistoryVisibilityChanged=
            ChartSetInteger(0,CHART_SHOW_TRADE_HISTORY,false);
         if(!TradeHistoryVisibilityChanged)
            PrintFormat("SMC: unable to hide trade-history markers (error=%d).",
                        GetLastError());
      }
   }
   ConfigureDrawing();
   if(ShowControlPanel && !SMC_PanelDraw(PanelObjectPrefix,PanelState))
   {
      SMC_PanelDelete(PanelObjectPrefix);
      return INIT_FAILED;
   }
   SetIndexBuffer(0,CandleOpen,INDICATOR_DATA);
   SetIndexBuffer(1,CandleHigh,INDICATOR_DATA);
   SetIndexBuffer(2,CandleLow,INDICATOR_DATA);
   SetIndexBuffer(3,CandleClose,INDICATOR_DATA);
   SetIndexBuffer(4,CandleColorIndex,INDICATOR_COLOR_INDEX);
   ArraySetAsSeries(CandleOpen,true);
   ArraySetAsSeries(CandleHigh,true);
   ArraySetAsSeries(CandleLow,true);
   ArraySetAsSeries(CandleClose,true);
   ArraySetAsSeries(CandleColorIndex,true);
   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,2);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,BullColor(false));
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,BearColor(false));
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Smart Money Concepts [LuxAlgo]");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   DeleteSMCObjects(ObjectPrefix);
   SMC_PanelDelete(PanelObjectPrefix);
   if(TradeHistoryVisibilityCaptured && TradeHistoryVisibilityChanged &&
      PreviousTradeHistoryVisibility)
   {
      long tradeHistoryVisible=0;
      if(ChartGetInteger(0,CHART_SHOW_TRADE_HISTORY,0,tradeHistoryVisible) &&
         tradeHistoryVisible==0 &&
         !ChartSetInteger(0,CHART_SHOW_TRADE_HISTORY,true))
         PrintFormat("SMC: unable to restore trade-history visibility (error=%d).",
                     GetLastError());
   }
}

bool ProcessNewBar(const int ratesTotal,const datetime &time[],const double &open[],
                   const double &high[],const double &low[],const double &close[])
{
   if(!SMC_AdvanceCalculationCaches(ratesTotal,LastRatesTotal,MaxBarsToProcess,
                                   high,low,close,OrderBlockFilter,
                                   CumulativeRangeClosedSum,ParsedHighs,
                                   ParsedLows,AtrCache,MeanRangeCache,
                                   TrueRangeCache,SwingHigh,SwingLow,
                                   InternalHigh,InternalLow,EqualHigh,EqualLow,
                                   TrailingTop,TrailingBottom,LatestStructures))
      return false;

   StructureEvent structureEvents[2];
   int structureEventCount=0;
   SMC_DetectStructure(false,SwingLength,SwingLeg,SwingHigh,SwingLow,SwingBias,
                       1,ratesTotal,time,open,high,low,close,false,SwingLabelSize,
                       SwingHigh,SwingLow,TrailingTop,TrailingBottom,
                       TrailingAnchorTime,ParsedHighs,ParsedLows,
                       true,OrderBlocks,
                       structureEvents,structureEventCount);
   RenderStructureEvents(structureEvents,structureEventCount);
   SMC_DetectStructure(true,5,InternalLeg,InternalHigh,InternalLow,InternalBias,
                       1,ratesTotal,time,open,high,low,close,
                       InternalConfluenceFilter,InternalLabelSize,
                       SwingHigh,SwingLow,TrailingTop,TrailingBottom,
                       TrailingAnchorTime,ParsedHighs,ParsedLows,
                       true,OrderBlocks,
                       structureEvents,structureEventCount);
   RenderStructureEvents(structureEvents,structureEventCount);
   if(ShowEqualHighsLows)
      DetectEqualHighLow(EqualHighLowConfirmationBars,EqualLeg,EqualHigh,EqualLow,
                         1,ratesTotal,time,high,low,AtrCache);
   if(ShowSwingPoints)
      DrawSwingLabels(DrawConfig,time,high,low,1,SwingLength,SwingHigh,SwingLow);

   SMC_UpdateTrailingLevels(true,time[0],high[0],low[0],
                            TrailingTop,TrailingBottom);
   RemoveMitigatedOrderBlocks(high[1],low[1],close[1],time[1],true);
   if(ColorCandles)
   {
      CandleOpen[1]=open[1];
      CandleHigh[1]=high[1];
      CandleLow[1]=low[1];
      CandleClose[1]=close[1];
      CandleColorIndex[1]=(InternalBias>0 ? 0 : 1);
      CandleOpen[0]=open[0];
      CandleHigh[0]=high[0];
      CandleLow[0]=low[0];
      CandleClose[0]=close[0];
      CandleColorIndex[0]=(InternalBias>0 ? 0 : 1);
   }
   else
   {
      CandleOpen[1]=EMPTY_VALUE;
      CandleHigh[1]=EMPTY_VALUE;
      CandleLow[1]=EMPTY_VALUE;
      CandleClose[1]=EMPTY_VALUE;
      CandleOpen[0]=EMPTY_VALUE;
      CandleHigh[0]=EMPTY_VALUE;
      CandleLow[0]=EMPTY_VALUE;
      CandleClose[0]=EMPTY_VALUE;
   }

   if(RefreshCurrentFVGThreshold())
      UpdateFairValueGapsOnTick(time[0],high[0],low[0]);
   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0) periodSeconds=60;
   DrawOrderBlockObjects(DrawConfig,OrderBlocks,time[0],periodSeconds);
   datetime structureRight=time[0]+periodSeconds;
   for(int i=0;i<ArraySize(LatestStructures);i++)
      if(LatestStructures[i].valid)
         LatestStructures[i].rightTime=structureRight;
   if(RuntimeShowInternalStructure || RuntimeShowSwingStructure)
   {
      ExtendPresentStructures(DrawConfig,LatestStructures,
                              PresentStructuresDirty,structureRight);
      RenderPresentStructures(DrawConfig,LatestStructures,PresentStructuresDirty);
   }
   RenderPreviousLevels(DrawConfig,ratesTotal,time,high,low);
   DrawTrailingLevels(DrawConfig,TrailingTop,TrailingBottom,SwingBias,
                      time[0],periodSeconds);
   DrawPremiumDiscount(DrawConfig,TrailingTop,TrailingBottom,
                       TrailingAnchorTime,time[0],periodSeconds);
   UpdateMarketBiasLabel(DrawConfig,SwingBias,InternalBias);
   ChartRedraw(0);
   LastProcessedBar=time[0];
   LastRatesTotal=ratesTotal;
   return true;
}

void UpdateCurrentBar(const int ratesTotal,const datetime &time[],
                      const double &open[],const double &high[],
                      const double &low[],const double &close[])
{
   SMC_UpdateCurrentCalculationValues(high[0],low[0],close[1],ratesTotal,
                                      OrderBlockFilter,
                                      CumulativeRangeClosedSum,ParsedHighs,
                                      ParsedLows,AtrCache,MeanRangeCache,
                                      TrueRangeCache);
   UpdateTrailingLevelsOnTick(time[0],high[0],low[0],PeriodSeconds(_Period));
   if(ColorCandles)
   {
      CandleOpen[0]=open[0];
      CandleHigh[0]=high[0];
      CandleLow[0]=low[0];
      CandleClose[0]=close[0];
      CandleColorIndex[0]=(InternalBias>0 ? 0 : 1);
   }
   else
   {
      CandleOpen[0]=EMPTY_VALUE;
      CandleHigh[0]=EMPTY_VALUE;
      CandleLow[0]=EMPTY_VALUE;
      CandleClose[0]=EMPTY_VALUE;
   }

   UpdateFairValueGapsOnTick(time[0],high[0],low[0]);
   int periodSeconds=MathMax(1,PeriodSeconds(_Period));
   datetime structureRight=time[0]+periodSeconds;
   for(int i=0;i<ArraySize(LatestStructures);i++)
      if(LatestStructures[i].valid)
         LatestStructures[i].rightTime=structureRight;
   if(RuntimeShowInternalStructure || RuntimeShowSwingStructure)
   {
      ExtendPresentStructures(DrawConfig,LatestStructures,
                              PresentStructuresDirty,structureRight);
      RenderPresentStructures(DrawConfig,LatestStructures,PresentStructuresDirty);
   }
}

bool RebuildHistoricalState(const int ratesTotal,const datetime &time[],
                            const double &open[],const double &high[],
                            const double &low[],const double &close[])
{
   LastProcessedBar=time[0];
   LastRatesTotal=ratesTotal;
   AlertsArmed=false;
   DeleteSMCObjects(ObjectPrefix);
   ResetState();

   int count=MathMin(ratesTotal,MaxBarsToProcess);
   for(int i=ratesTotal-1;i>=count;i--)
   {
      CandleOpen[i]=EMPTY_VALUE;
      CandleHigh[i]=EMPTY_VALUE;
      CandleLow[i]=EMPTY_VALUE;
      CandleClose[i]=EMPTY_VALUE;
      CandleColorIndex[i]=0;
   }
   int oldest=count-1;
   if(ArrayResize(AtrCache,count)!=count ||
      ArrayResize(MeanRangeCache,count)!=count ||
      ArrayResize(TrueRangeCache,count)!=count ||
      ArrayResize(ParsedHighs,count)!=count ||
      ArrayResize(ParsedLows,count)!=count)
   {
      PrintFormat("SMC: unable to allocate calculation caches (error=%d).",
                  GetLastError());
      return false;
   }
   ArraySetAsSeries(AtrCache,true);
   ArraySetAsSeries(MeanRangeCache,true);
   ArraySetAsSeries(TrueRangeCache,true);
   ArraySetAsSeries(ParsedHighs,true);
   ArraySetAsSeries(ParsedLows,true);
   for(int i=oldest;i>=0;i--)
   {
      CandleOpen[i]=EMPTY_VALUE; CandleHigh[i]=EMPTY_VALUE;
      CandleLow[i]=EMPTY_VALUE; CandleClose[i]=EMPTY_VALUE;
      CandleColorIndex[i]=0;
   }
   if(!SMC_InitializeCalculationCaches(ratesTotal,count,high,low,close,
                                       OrderBlockFilter,ParsedHighs,ParsedLows,
                                       AtrCache,MeanRangeCache,TrueRangeCache,
                                       CumulativeRangeClosedSum))
   {
      Print("SMC: unable to initialize calculation caches.");
      return false;
   }

   for(int i=oldest-MathMax(SwingLength,EqualHighLowConfirmationBars)-1;i>=0;i--)
   {
      if(i+1>=ratesTotal) continue;
      SMC_UpdateTrailingLevels(true,time[i],high[i],low[i],
                               TrailingTop,TrailingBottom);
      if(i>0)
      {
         StructureEvent structureEvents[2];
         int structureEventCount=0;
         SMC_DetectStructure(false,SwingLength,SwingLeg,SwingHigh,SwingLow,SwingBias,
                             i,ratesTotal,time,open,high,low,close,false,
                             SwingLabelSize,SwingHigh,SwingLow,
                             TrailingTop,TrailingBottom,TrailingAnchorTime,
                             ParsedHighs,ParsedLows,true,
                             OrderBlocks,
                             structureEvents,structureEventCount);
         RenderStructureEvents(structureEvents,structureEventCount);
         SMC_DetectStructure(true,5,InternalLeg,InternalHigh,InternalLow,InternalBias,
                             i,ratesTotal,time,open,high,low,close,
                             InternalConfluenceFilter,InternalLabelSize,
                             SwingHigh,SwingLow,TrailingTop,TrailingBottom,
                             TrailingAnchorTime,ParsedHighs,ParsedLows,
                             true,OrderBlocks,
                             structureEvents,structureEventCount);
         RenderStructureEvents(structureEvents,structureEventCount);
         if(ShowEqualHighsLows)
            DetectEqualHighLow(EqualHighLowConfirmationBars,EqualLeg,
                               EqualHigh,EqualLow,i,ratesTotal,time,high,low,AtrCache);
         if(ShowSwingPoints)
            DrawSwingLabels(DrawConfig,time,high,low,i,SwingLength,
                            SwingHigh,SwingLow);
         RemoveMitigatedOrderBlocks(high[i],low[i],close[i],time[i],false);
      }
      if(ColorCandles)
      {
         CandleOpen[i]=open[i]; CandleHigh[i]=high[i];
         CandleLow[i]=low[i]; CandleClose[i]=close[i];
         CandleColorIndex[i]=(InternalBias>0 ? 0 : 1);
      }
   }

   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0) periodSeconds=60;
   datetime structureRight=time[0]+periodSeconds;
   for(int i=0;i<ArraySize(LatestStructures);i++)
      if(LatestStructures[i].valid)
         LatestStructures[i].rightTime=structureRight;
   if(RuntimeShowInternalStructure || RuntimeShowSwingStructure)
      RenderPresentStructures(DrawConfig,LatestStructures,PresentStructuresDirty);
   DrawOrderBlockObjects(DrawConfig,OrderBlocks,time[0],periodSeconds);
   DrawFVGs();
   AlertsArmed=true;
   if(RuntimeShowDailyLevels)
      DrawPreviousPeriodLevels(DrawConfig,PERIOD_D1,"D",DailyLevelsStyle,DailyLevelsColor,
                               time[0],ratesTotal,time,high,low);
   if(RuntimeShowWeeklyLevels)
      DrawPreviousPeriodLevels(DrawConfig,PERIOD_W1,"W",WeeklyLevelsStyle,WeeklyLevelsColor,
                               time[0],ratesTotal,time,high,low);
   if(RuntimeShowMonthlyLevels)
      DrawPreviousPeriodLevels(DrawConfig,PERIOD_MN1,"M",MonthlyLevelsStyle,MonthlyLevelsColor,
                               time[0],ratesTotal,time,high,low);
   DrawTrailingLevels(DrawConfig,TrailingTop,TrailingBottom,SwingBias,
                      time[0],periodSeconds);
   DrawPremiumDiscount(DrawConfig,TrailingTop,TrailingBottom,
                       TrailingAnchorTime,time[0],periodSeconds);
   UpdateMarketBiasLabel(DrawConfig,SwingBias,InternalBias);
   if(ShowControlPanel)
      SMC_PanelDraw(PanelObjectPrefix,PanelState);
   ChartRedraw(0);
   LastRatesTotal=ratesTotal;
   return true;
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,
                  const string &sparam)
{
   if(!ShowControlPanel || id!=CHARTEVENT_OBJECT_CLICK)
      return;
   ENUM_SMC_PANEL_GROUP group=SMC_PanelHandleClick(PanelObjectPrefix,sparam,
                                                   PanelState);
   if(group==SMC_PANEL_NONE)
      return;

   if(group==SMC_PANEL_STRUCTURE)
   {
      RuntimeShowInternalStructure=PanelState.structures &&
                                   (ShowInternalStructure ||
                                    !ShowSwingStructure);
      RuntimeShowSwingStructure=PanelState.structures &&
                                (ShowSwingStructure ||
                                 !ShowInternalStructure);
   }
   else if(group==SMC_PANEL_ORDER_BLOCKS)
   {
      RuntimeShowInternalOrderBlocks=PanelState.orderBlocks &&
                                     (ShowInternalOrderBlocks ||
                                      !ShowSwingOrderBlocks);
      RuntimeShowSwingOrderBlocks=PanelState.orderBlocks &&
                                  (ShowSwingOrderBlocks ||
                                   !ShowInternalOrderBlocks);
   }
   else if(group==SMC_PANEL_FVG)
      RuntimeShowFairValueGaps=PanelState.fairValueGaps;
   else if(group==SMC_PANEL_PREVIOUS_LEVELS)
   {
      bool anyPreviousLevel=ShowDailyLevels || ShowWeeklyLevels ||
                            ShowMonthlyLevels;
      RuntimeShowDailyLevels=PanelState.previousLevels &&
                             (ShowDailyLevels || !anyPreviousLevel);
      RuntimeShowWeeklyLevels=PanelState.previousLevels &&
                              (ShowWeeklyLevels || !anyPreviousLevel);
      RuntimeShowMonthlyLevels=PanelState.previousLevels &&
                               (ShowMonthlyLevels || !anyPreviousLevel);
   }
   else if(group==SMC_PANEL_STRONG_WEAK)
      RuntimeShowStrongWeakHighLow=PanelState.strongWeak;

   ConfigureDrawing();
   if(ShowControlPanel)
      SMC_PanelDraw(PanelObjectPrefix,PanelState);
   bool groupEnabled=(group==SMC_PANEL_STRUCTURE ? PanelState.structures :
                      group==SMC_PANEL_ORDER_BLOCKS ? PanelState.orderBlocks :
                      group==SMC_PANEL_FVG ? PanelState.fairValueGaps :
                      group==SMC_PANEL_PREVIOUS_LEVELS ? PanelState.previousLevels :
                      PanelState.strongWeak);
   if(group==SMC_PANEL_ORDER_BLOCKS)
   {
      if(groupEnabled)
      {
         DeleteObjectsWithPrefix(ObjectPrefix+"OB_");
         datetime currentBarTime=iTime(_Symbol,_Period,0);
         if(currentBarTime<=0)
            PrintFormat("SMC: unable to read current bar time while enabling OB display (error=%d).",
                        GetLastError());
         else
            DrawOrderBlockObjects(DrawConfig,OrderBlocks,currentBarTime,
                                  PeriodSeconds(_Period));
      }
      else
         HidePanelGroupObjects(group);
   }
   else if(groupEnabled)
      LastProcessedBar=0;
   else
      HidePanelGroupObjects(group);
   ChartRedraw(0);
}

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],const double &high[],
                const double &low[],const double &close[],const long &tick_volume[],
                const long &volume[],const int &spread[])
{
   if(rates_total<MathMax(SwingLength,EqualHighLowConfirmationBars)+3)
      return 0;
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   if(prev_calculated>0 && LastProcessedBar>0 &&
      time[0]>LastProcessedBar)
   {
      if(ProcessNewBar(rates_total,time,open,high,low,close))
         return rates_total;
   }
   if(prev_calculated>0 && LastProcessedBar==time[0])
   {
      UpdateCurrentBar(rates_total,time,open,high,low,close);
      return rates_total;
   }
   if(!RebuildHistoricalState(rates_total,time,open,high,low,close))
      return 0;
   return rates_total;
}
