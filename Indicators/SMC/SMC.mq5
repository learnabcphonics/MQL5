// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#property copyright " Smart Money Concepts"
#property version   "1.00"
#property strict
#property indicator_chart_window
#include <SMC/SMC_Types.mqh>
#include <SMC/SMC_Engine.mqh>
#include <SMC/SMC_State.mqh>
#include <SMC/SMC_Palette.mqh>
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_label1  "SMC trend candles"

input group "Smart Money Concepts"
input bool ColorCandles = false;
input int MaxBarsToProcess = 2000;

input group "Chart Display"
input bool HideTradeHistoryMarkers = true;

input group "Market Bias"
input bool ShowMarketBias = true;

input group "Real Time Internal Structure"
input bool ShowInternalStructure = true;
input ENUM_SMC_SHOW InternalBullishStructure = SMC_ALL;
input ENUM_SMC_SHOW InternalBearishStructure = SMC_ALL;
input bool InternalConfluenceFilter = false;
input ENUM_SMC_SIZE InternalLabelSize = SMC_TINY;

input group "Real Time Swing Structure"
input bool ShowSwingStructure = true;
input ENUM_SMC_SHOW SwingBullishStructure = SMC_ALL;
input ENUM_SMC_SHOW SwingBearishStructure = SMC_ALL;
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

input group "EQH/EQL"
input bool ShowEqualHighsLows = true;
input int EqualHighLowConfirmationBars = 3;
input double EqualHighLowThreshold = 0.1;
input ENUM_SMC_SIZE EqualHighLowLabelSize = SMC_TINY;

input group "Fair Value Gaps"
input bool ShowFairValueGaps = false;
input bool FairValueGapAutoThreshold = false;
input int FairValueGapExtend = 1;
input int MaxFairValueGapsToShow = 5;

input group "Previous Period Highs & Lows"
input bool ShowDailyLevels = false;
input ENUM_SMC_LINE_STYLE DailyLevelsStyle = SMC_SOLID;
input bool ShowWeeklyLevels = false;
input ENUM_SMC_LINE_STYLE WeeklyLevelsStyle = SMC_SOLID;
input bool ShowMonthlyLevels = false;
input ENUM_SMC_LINE_STYLE MonthlyLevelsStyle = SMC_SOLID;

input group "Premium & Discount Zones"
input bool ShowPremiumDiscountZones = false;

double CandleOpen[], CandleHigh[], CandleLow[], CandleClose[], CandleColorIndex[];
string ObjectPrefix = "SMC_";
SMC_DrawConfig DrawConfig;
SMC_State State;
bool PreviousTradeHistoryVisibility = false;
bool TradeHistoryVisibilityCaptured = false;
bool TradeHistoryVisibilityChanged = false;
ENUM_TIMEFRAMES LastChartPeriod = PERIOD_CURRENT;
bool TimeframeSwitchPending = false;

color BullColor(const bool internal)
{
   return SMC_COLOR_BULLISH;
}

color BearColor(const bool internal)
{
   return SMC_COLOR_BEARISH;
}

void ConfigureDrawing()
{
   DrawConfig.objectPrefix=ObjectPrefix;
   DrawConfig.symbol=_Symbol;
   DrawConfig.chartTimeframe=_Period;
   DrawConfig.showMarketBias=ShowMarketBias;
   DrawConfig.showInternalStructure=ShowInternalStructure;
   DrawConfig.showSwingStructure=ShowSwingStructure;
   DrawConfig.internalBullishStructure=InternalBullishStructure;
   DrawConfig.internalBearishStructure=InternalBearishStructure;
   DrawConfig.swingBullishStructure=SwingBullishStructure;
   DrawConfig.swingBearishStructure=SwingBearishStructure;
   DrawConfig.internalBullishColor=SMC_COLOR_BULLISH;
   DrawConfig.internalBearishColor=SMC_COLOR_BEARISH;
   DrawConfig.swingBullishColor=SMC_COLOR_BULLISH;
   DrawConfig.swingBearishColor=SMC_COLOR_BEARISH;
   DrawConfig.showInternalOrderBlocks=ShowInternalOrderBlocks;
   DrawConfig.showSwingOrderBlocks=ShowSwingOrderBlocks;
   DrawConfig.internalOrderBlocksToShow=InternalOrderBlocksToShow;
   DrawConfig.swingOrderBlocksToShow=SwingOrderBlocksToShow;
   DrawConfig.orderBlockExtend=OrderBlockExtend;
   DrawConfig.internalBullishOBColor=SMC_COLOR_BULLISH;
   DrawConfig.internalBearishOBColor=SMC_COLOR_BEARISH;
   DrawConfig.swingBullishOBColor=SMC_COLOR_BULLISH;
   DrawConfig.swingBearishOBColor=SMC_COLOR_BEARISH;
   DrawConfig.showSwingPoints=ShowSwingPoints;
   DrawConfig.swingLength=SwingLength;
   DrawConfig.showStrongWeakHighLow=ShowStrongWeakHighLow;
   DrawConfig.showPremiumDiscountZones=ShowPremiumDiscountZones;
   DrawConfig.premiumZoneColor=SMC_COLOR_BEARISH;
   DrawConfig.equilibriumZoneColor=SMC_COLOR_EQUILIBRIUM;
   DrawConfig.discountZoneColor=SMC_COLOR_BULLISH;
   DrawConfig.showDailyLevels=ShowDailyLevels;
   DrawConfig.showWeeklyLevels=ShowWeeklyLevels;
   DrawConfig.showMonthlyLevels=ShowMonthlyLevels;
   DrawConfig.dailyLevelsStyle=DailyLevelsStyle;
   DrawConfig.weeklyLevelsStyle=WeeklyLevelsStyle;
   DrawConfig.monthlyLevelsStyle=MonthlyLevelsStyle;
   DrawConfig.dailyLevelsColor=SMC_COLOR_PREVIOUS_LEVEL;
   DrawConfig.weeklyLevelsColor=SMC_COLOR_PREVIOUS_LEVEL;
   DrawConfig.monthlyLevelsColor=SMC_COLOR_PREVIOUS_LEVEL;
}

#include <SMC/SMC_Draw.mqh>

void RemoveMitigatedOrderBlocks(const double high,const double low,const double close,
                               const datetime barTime)
{
   OrderBlockState removed[];
   int removedCount=0;
   if(!SMC_RemoveMitigatedOrderBlocks(high,low,close,barTime,
                                      OrderBlockMitigation,State,
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
   }
}

void RenderStructureEvents(const StructureEvent &events[],const int eventCount)
{
   datetime rightTime=0;
   for(int i=0;i<eventCount;i++)
   {
      StructureEvent event=events[i];
      if(!IsStructureVisible(DrawConfig,event.internal,event.bullish,event.tag))
         continue;
      if(rightTime==0)
         rightTime=event.time+PeriodSeconds(_Period);
      color lineColor=(event.bullish ?
                       SMC_DrawBullColor(DrawConfig,event.internal) :
                       SMC_DrawBearColor(DrawConfig,event.internal));
      string id=(event.internal ? "I_" : "S_")+
                IntegerToString((int)event.time);
      DrawHorizontalStructure(DrawConfig,State.LatestStructures,
                              State.PresentStructuresDirty,id,event.pivot,rightTime,
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
   if(ShowEqualHighsLows)
      DrawEqualLevelEvent(DrawConfig,event,
                          event.high ? BearColor(false) : BullColor(false),
                          EqualHighLowLabelSize);
}

void DrawActiveFairValueGaps(const MqlRates &bars[])
{
   if(!ShowFairValueGaps || ArraySize(bars)==0)
      return;
   int gapCount=ArraySize(State.FairValueGaps);
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
         if(newest<0 || State.FairValueGaps[i].time>State.FairValueGaps[newest].time)
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
      FairValueGapState gap=State.FairValueGaps[i];
      if(!selected[i])
      {
         DeleteFairValueGap(DrawConfig,gap);
         continue;
      }
      gap.right=right;
      color gapColor=(gap.bias>0 ? SMC_COLOR_BULLISH : SMC_COLOR_BEARISH);
      DrawFairValueGap(DrawConfig,gap,gapColor);
   }
}

void UpdateFairValueGapsOnTick(const datetime chartBarTime,
                               const double currentHigh,const double currentLow)
{
   if(!ShowFairValueGaps)
      return;
   if(State.FVGUpdateStateInitialized && State.LastFVGUpdateBarTime==chartBarTime &&
      State.LastFVGUpdateHigh==currentHigh && State.LastFVGUpdateLow==currentLow)
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
                               FairValueGapExtend,FairValueGapAutoThreshold,
                               _Point,State,
                               removed,removedCount,added,addedCount))
   {
      Print("SMC: failed to update fair value gap analysis.");
      return;
   }
   for(int i=0;i<removedCount;i++)
      DeleteFairValueGap(DrawConfig,removed[i]);
   DrawActiveFairValueGaps(bars);
   State.LastFVGUpdateBarTime=chartBarTime;
   State.LastFVGUpdateHigh=currentHigh;
   State.LastFVGUpdateLow=currentLow;
   State.FVGUpdateStateInitialized=true;
}

bool RefreshCurrentFVGThreshold()
{
   if(!ShowFairValueGaps)
      return true;
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int copied=CopyRates(_Symbol,_Period,0,MaxBarsToProcess,bars);
   if(copied<3)
   {
      PrintFormat("SMC: unable to refresh FVG threshold for chart timeframe %s (bars=%d, error=%d).",
                  EnumToString(_Period),copied,GetLastError());
      return false;
   }
   return SMC_UpdateFVGThreshold(bars,_Point,State);
}

void DrawFVGs()
{
   if(!ShowFairValueGaps)
      return;
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
                                State))
   {
      Print("SMC: failed to analyze historical fair value gaps.");
      return;
   }
   DrawActiveFairValueGaps(bars);
}

void UpdateTrailingLevelsOnTick(const datetime currentTime,const double currentHigh,
                                const double currentLow,const int periodSeconds)
{
   double previousTop=State.TrailingTop.current;
   datetime previousTopTime=State.TrailingTop.time;
   double previousBottom=State.TrailingBottom.current;
   datetime previousBottomTime=State.TrailingBottom.time;
   bool hadTrailingTop=State.TrailingTop.initialized;
   bool hadTrailingBottom=State.TrailingBottom.initialized;
   SMC_UpdateTrailingLevels(true,currentTime,currentHigh,currentLow,
                            State);
   bool levelsChanged=hadTrailingTop!=State.TrailingTop.initialized ||
                      hadTrailingBottom!=State.TrailingBottom.initialized ||
                      previousTop!=State.TrailingTop.current ||
                      previousTopTime!=State.TrailingTop.time ||
                      previousBottom!=State.TrailingBottom.current ||
                      previousBottomTime!=State.TrailingBottom.time;
   if(!levelsChanged)
      return;
   SMC_DrawUpdateTrailingLevels(DrawConfig,State.TrailingTop,State.TrailingBottom,State.SwingBias,
                                State.TrailingAnchorTime,currentTime,periodSeconds);
}

int OnInit()
{
   if(SwingLength<10 || MaxBarsToProcess<MathMax(SwingLength,EqualHighLowConfirmationBars)+3 ||
      MaxBarsToProcess>10000 || EqualHighLowConfirmationBars<1 ||
      InternalOrderBlocksToShow<1 || InternalOrderBlocksToShow>20 ||
      SwingOrderBlocksToShow<1 || SwingOrderBlocksToShow>20 ||
      OrderBlockExtend<1 || OrderBlockExtend>1000 ||
      (ShowFairValueGaps &&
       (FairValueGapExtend<0 || MaxFairValueGapsToShow<1 ||
        MaxFairValueGapsToShow>100)) || EqualHighLowThreshold<0.0 ||
      EqualHighLowThreshold>0.5)
      return INIT_PARAMETERS_INCORRECT;
   string legacyObjectPrefix="SC"+
                             IntegerToString((int)(ChartID()%100000))+"_";
   DeleteObjectsWithPrefix(legacyObjectPrefix);
   ObjectPrefix="SMC"+IntegerToString((long)ChartID())+"_";
   DeleteSMCObjects(ObjectPrefix);
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
   LastChartPeriod=_Period;
   TimeframeSwitchPending=false;
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
   IndicatorSetString(INDICATOR_SHORTNAME,"Smart Money Concepts");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   DeleteSMCObjects(ObjectPrefix);
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

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id!=CHARTEVENT_CHART_CHANGE)
      return;
   ENUM_TIMEFRAMES currentPeriod=(ENUM_TIMEFRAMES)ChartPeriod(0);
   if(currentPeriod==PERIOD_CURRENT || currentPeriod==LastChartPeriod)
      return;
   LastChartPeriod=currentPeriod;
   TimeframeSwitchPending=true;
   ConfigureDrawing();
   DeleteSMCObjects(ObjectPrefix);
   if(!SMC_ResetState(State))
      Print("SMC: failed to reset state after chart timeframe change.");
   ChartRedraw(0);
}

bool ProcessNewBar(const int ratesTotal,const datetime &time[],const double &open[],
                   const double &high[],const double &low[],const double &close[])
{
   if(!SMC_AdvanceCalculationCaches(ratesTotal,MaxBarsToProcess,
                                   high,low,close,OrderBlockFilter,State))
      return false;

   StructureEvent structureEvents[2];
   int structureEventCount=0;
   SMC_DetectStructure(false,SwingLength,1,ratesTotal,time,open,high,low,close,
                       false,SwingLabelSize,true,State,
                       structureEvents,structureEventCount);
   RenderStructureEvents(structureEvents,structureEventCount);
   SMC_DetectStructure(true,5,1,ratesTotal,time,open,high,low,close,
                       InternalConfluenceFilter,InternalLabelSize,true,State,
                       structureEvents,structureEventCount);
   RenderStructureEvents(structureEvents,structureEventCount);
   if(ShowEqualHighsLows)
      DetectEqualHighLow(EqualHighLowConfirmationBars,State.EqualLeg,State.EqualHigh,State.EqualLow,
                         1,ratesTotal,time,high,low,State.AtrCache);
   if(ShowSwingPoints)
      DrawSwingLabels(DrawConfig,time,high,low,1,SwingLength,State.SwingHigh,State.SwingLow);

   SMC_UpdateTrailingLevels(true,time[0],high[0],low[0],
                            State);
   RemoveMitigatedOrderBlocks(high[1],low[1],close[1],time[1]);
   if(ColorCandles)
   {
      CandleOpen[1]=open[1];
      CandleHigh[1]=high[1];
      CandleLow[1]=low[1];
      CandleClose[1]=close[1];
      CandleColorIndex[1]=(State.InternalBias>0 ? 0 : 1);
      CandleOpen[0]=open[0];
      CandleHigh[0]=high[0];
      CandleLow[0]=low[0];
      CandleClose[0]=close[0];
      CandleColorIndex[0]=(State.InternalBias>0 ? 0 : 1);
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

   if(ShowFairValueGaps && RefreshCurrentFVGThreshold())
      UpdateFairValueGapsOnTick(time[0],high[0],low[0]);
   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0) periodSeconds=60;
   DrawOrderBlockObjects(DrawConfig,State.OrderBlocks,time[0],periodSeconds);
   datetime structureRight=time[0]+periodSeconds;
   for(int i=0;i<ArraySize(State.LatestStructures);i++)
      if(State.LatestStructures[i].valid)
         State.LatestStructures[i].rightTime=structureRight;
   if(ShowInternalStructure || ShowSwingStructure)
   {
      ExtendPresentStructures(DrawConfig,State.LatestStructures,
                              State.PresentStructuresDirty,structureRight);
      RenderPresentStructures(DrawConfig,State.LatestStructures,State.PresentStructuresDirty);
   }
   RenderPreviousLevels(DrawConfig,ratesTotal,time,high,low);
   DrawTrailingLevels(DrawConfig,State.TrailingTop,State.TrailingBottom,State.SwingBias,
                      time[0],periodSeconds);
   DrawPremiumDiscount(DrawConfig,State.TrailingTop,State.TrailingBottom,
                       State.TrailingAnchorTime,time[0],periodSeconds);
   UpdateMarketBiasLabel(DrawConfig,State.SwingBias,State.InternalBias);
   ChartRedraw(0);
   State.LastProcessedBar=time[0];
   State.LastRatesTotal=ratesTotal;
   return true;
}

void UpdateCurrentBar(const int ratesTotal,const datetime &time[],
                      const double &open[],const double &high[],
                      const double &low[],const double &close[])
{
   SMC_UpdateCurrentCalculationValues(high[0],low[0],close[1],ratesTotal,
                                      OrderBlockFilter,State);
   UpdateTrailingLevelsOnTick(time[0],high[0],low[0],PeriodSeconds(_Period));
   DrawPremiumDiscount(DrawConfig,State.TrailingTop,State.TrailingBottom,
                       State.TrailingAnchorTime,time[0],PeriodSeconds(_Period));
   if(ColorCandles)
   {
      CandleOpen[0]=open[0];
      CandleHigh[0]=high[0];
      CandleLow[0]=low[0];
      CandleClose[0]=close[0];
      CandleColorIndex[0]=(State.InternalBias>0 ? 0 : 1);
   }
   else
   {
      CandleOpen[0]=EMPTY_VALUE;
      CandleHigh[0]=EMPTY_VALUE;
      CandleLow[0]=EMPTY_VALUE;
      CandleClose[0]=EMPTY_VALUE;
   }

   if(ShowFairValueGaps)
      UpdateFairValueGapsOnTick(time[0],high[0],low[0]);
   int periodSeconds=MathMax(1,PeriodSeconds(_Period));
   datetime structureRight=time[0]+periodSeconds;
   for(int i=0;i<ArraySize(State.LatestStructures);i++)
      if(State.LatestStructures[i].valid)
         State.LatestStructures[i].rightTime=structureRight;
   if(ShowInternalStructure || ShowSwingStructure)
   {
      ExtendPresentStructures(DrawConfig,State.LatestStructures,
                              State.PresentStructuresDirty,structureRight);
      RenderPresentStructures(DrawConfig,State.LatestStructures,State.PresentStructuresDirty);
   }
}

bool RebuildHistoricalState(const int ratesTotal,const datetime &time[],
                            const double &open[],const double &high[],
                            const double &low[],const double &close[])
{
   if(!SMC_ResetState(State))
      return false;
   State.LastProcessedBar=time[0];
   State.LastRatesTotal=ratesTotal;
   DeleteSMCObjects(ObjectPrefix);

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
   if(ArrayResize(State.AtrCache,count)!=count ||
      ArrayResize(State.MeanRangeCache,count)!=count ||
      ArrayResize(State.TrueRangeCache,count)!=count ||
      ArrayResize(State.ParsedHighs,count)!=count ||
      ArrayResize(State.ParsedLows,count)!=count)
   {
      PrintFormat("SMC: unable to allocate calculation caches (error=%d).",
                  GetLastError());
      return false;
   }
   ArraySetAsSeries(State.AtrCache,true);
   ArraySetAsSeries(State.MeanRangeCache,true);
   ArraySetAsSeries(State.TrueRangeCache,true);
   ArraySetAsSeries(State.ParsedHighs,true);
   ArraySetAsSeries(State.ParsedLows,true);
   for(int i=oldest;i>=0;i--)
   {
      CandleOpen[i]=EMPTY_VALUE; CandleHigh[i]=EMPTY_VALUE;
      CandleLow[i]=EMPTY_VALUE; CandleClose[i]=EMPTY_VALUE;
      CandleColorIndex[i]=0;
   }
   if(!SMC_InitializeCalculationCaches(ratesTotal,count,high,low,close,
                                       OrderBlockFilter,State))
   {
      Print("SMC: unable to initialize calculation caches.");
      return false;
   }

   for(int i=oldest-MathMax(SwingLength,EqualHighLowConfirmationBars)-1;i>=0;i--)
   {
      if(i+1>=ratesTotal) continue;
      SMC_UpdateTrailingLevels(true,time[i],high[i],low[i],
                               State);
      if(i>0)
      {
         StructureEvent structureEvents[2];
         int structureEventCount=0;
         SMC_DetectStructure(false,SwingLength,i,ratesTotal,time,open,high,low,
                             close,false,SwingLabelSize,true,State,
                             structureEvents,structureEventCount);
         RenderStructureEvents(structureEvents,structureEventCount);
         SMC_DetectStructure(true,5,i,ratesTotal,time,open,high,low,close,
                             InternalConfluenceFilter,InternalLabelSize,true,State,
                             structureEvents,structureEventCount);
         RenderStructureEvents(structureEvents,structureEventCount);
         if(ShowEqualHighsLows)
            DetectEqualHighLow(EqualHighLowConfirmationBars,State.EqualLeg,
                               State.EqualHigh,State.EqualLow,i,ratesTotal,time,high,low,State.AtrCache);
         if(ShowSwingPoints)
            DrawSwingLabels(DrawConfig,time,high,low,i,SwingLength,
                            State.SwingHigh,State.SwingLow);
         RemoveMitigatedOrderBlocks(high[i],low[i],close[i],time[i]);
      }
      if(ColorCandles)
      {
         CandleOpen[i]=open[i]; CandleHigh[i]=high[i];
         CandleLow[i]=low[i]; CandleClose[i]=close[i];
         CandleColorIndex[i]=(State.InternalBias>0 ? 0 : 1);
      }
   }

   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0) periodSeconds=60;
   datetime structureRight=time[0]+periodSeconds;
   for(int i=0;i<ArraySize(State.LatestStructures);i++)
      if(State.LatestStructures[i].valid)
         State.LatestStructures[i].rightTime=structureRight;
   if(ShowInternalStructure || ShowSwingStructure)
      RenderPresentStructures(DrawConfig,State.LatestStructures,State.PresentStructuresDirty);
   DrawOrderBlockObjects(DrawConfig,State.OrderBlocks,time[0],periodSeconds);
   if(ShowFairValueGaps)
      DrawFVGs();
   if(ShowDailyLevels)
      DrawPreviousPeriodLevels(DrawConfig,PERIOD_D1,"D",DailyLevelsStyle,SMC_COLOR_PREVIOUS_LEVEL,
                               time[0],ratesTotal,time,high,low);
   if(ShowWeeklyLevels)
      DrawPreviousPeriodLevels(DrawConfig,PERIOD_W1,"W",WeeklyLevelsStyle,SMC_COLOR_PREVIOUS_LEVEL,
                               time[0],ratesTotal,time,high,low);
   if(ShowMonthlyLevels)
      DrawPreviousPeriodLevels(DrawConfig,PERIOD_MN1,"M",MonthlyLevelsStyle,SMC_COLOR_PREVIOUS_LEVEL,
                               time[0],ratesTotal,time,high,low);
   DrawTrailingLevels(DrawConfig,State.TrailingTop,State.TrailingBottom,State.SwingBias,
                      time[0],periodSeconds);
   DrawPremiumDiscount(DrawConfig,State.TrailingTop,State.TrailingBottom,
                       State.TrailingAnchorTime,time[0],periodSeconds);
   UpdateMarketBiasLabel(DrawConfig,State.SwingBias,State.InternalBias);
   ChartRedraw(0);
   State.LastRatesTotal=ratesTotal;
   return true;
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
   if(TimeframeSwitchPending || LastChartPeriod!=_Period)
   {
      LastChartPeriod=_Period;
      TimeframeSwitchPending=false;
      ConfigureDrawing();
      if(!RebuildHistoricalState(rates_total,time,open,high,low,close))
         return 0;
      return rates_total;
   }
   if(prev_calculated>0 && State.LastProcessedBar>0 &&
      time[0]>State.LastProcessedBar)
   {
      if(ProcessNewBar(rates_total,time,open,high,low,close))
         return rates_total;
   }
   if(prev_calculated>0 && State.LastProcessedBar==time[0])
   {
      UpdateCurrentBar(rates_total,time,open,high,low,close);
      return rates_total;
   }
   if(!RebuildHistoricalState(rates_total,time,open,high,low,close))
      return 0;
   return rates_total;
}
