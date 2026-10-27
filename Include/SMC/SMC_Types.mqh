// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_TYPES_MQH
#define SMC_TYPES_MQH

enum ENUM_SMC_FILTER { SMC_ATR, SMC_CUMULATIVE_RANGE };
enum ENUM_SMC_MITIGATION { SMC_CLOSE, SMC_HIGH_LOW };
enum ENUM_SMC_SHOW { SMC_ALL, SMC_BOS, SMC_CHOCH };
enum ENUM_SMC_LINE_STYLE { SMC_SOLID, SMC_DASHED, SMC_DOTTED };
enum ENUM_SMC_SIZE { SMC_TINY=8, SMC_SMALL=10, SMC_NORMAL=12 };

struct SMC_DrawConfig
{
   string objectPrefix;
   string symbol;
   ENUM_TIMEFRAMES chartTimeframe;
   bool showMarketBias;
   bool showInternalStructure;
   bool showSwingStructure;
   ENUM_SMC_SHOW internalBullishStructure;
   ENUM_SMC_SHOW internalBearishStructure;
   ENUM_SMC_SHOW swingBullishStructure;
   ENUM_SMC_SHOW swingBearishStructure;
   color internalBullishColor;
   color internalBearishColor;
   color swingBullishColor;
   color swingBearishColor;
   bool showInternalOrderBlocks;
   bool showSwingOrderBlocks;
   int internalOrderBlocksToShow;
   int swingOrderBlocksToShow;
   int orderBlockExtend;
   color internalBullishOBColor;
   color internalBearishOBColor;
   color swingBullishOBColor;
   color swingBearishOBColor;
   bool showSwingPoints;
   int swingLength;
   bool showStrongWeakHighLow;
   bool showPremiumDiscountZones;
   color premiumZoneColor;
   color equilibriumZoneColor;
   color discountZoneColor;
   bool showDailyLevels;
   bool showWeeklyLevels;
   bool showMonthlyLevels;
   ENUM_SMC_LINE_STYLE dailyLevelsStyle;
   ENUM_SMC_LINE_STYLE weeklyLevelsStyle;
   ENUM_SMC_LINE_STYLE monthlyLevelsStyle;
   color dailyLevelsColor;
   color weeklyLevelsColor;
   color monthlyLevelsColor;
};

struct PivotState
{
   double current;
   double previous;
   bool previousInitialized;
   bool crossed;
   datetime time;
   int index;
   bool initialized;
};

struct StructureDisplayState
{
   PivotState pivot;
   datetime rightTime;
   string id;
   string tag;
   color lineColor;
   bool internal;
   bool bullish;
   ENUM_SMC_SIZE labelSize;
   bool valid;
};

struct OrderBlockState
{
   double high;
   double low;
   datetime time;
   datetime created;
   int bias;
   bool internal;
};

struct FairValueGapState
{
   double top;
   double bottom;
   datetime time;
   int bias;
   datetime left;
   datetime right;
   double firstTop;
   double firstBottom;
   double secondTop;
   double secondBottom;
};

struct StructureEvent
{
   PivotState pivot;
   datetime time;
   string tag;
   bool internal;
   bool bullish;
   bool liveBar;
   ENUM_SMC_SIZE labelSize;
};

struct EqualLevelEvent
{
   bool valid;
   bool high;
   datetime firstTime;
   datetime secondTime;
   datetime labelTime;
   double firstPrice;
   double secondPrice;
   bool liveBar;
};

#endif // SMC_TYPES_MQH
