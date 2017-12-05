import QtQuick 2.0
import CSI 1.0
import Traktor.Gui 1.0 as Traktor
import './../Definitions' as Definitions
import './../Widgets' as Widgets 
import '../../../Defines'


//------------------------------------------------------------------------------------------------------------------
//  LIST ITEM - DEFINES THE INFORMATION CONTAINED IN ONE LIST ITEM
//------------------------------------------------------------------------------------------------------------------
Rectangle {
  id: footer

  property string propertiesPath: ""
  property real  sortingKnobValue: 0.0
  property bool  isContentList:    qmlBrowser.isContentList
  
  // the given numbers are determined by the EContentListColumns in Traktor
  readonly property variant sortIds:          [0 ,  2     ,   3     ,  5   ,  28  ,  22     ,  27          ]
  readonly property variant sortNames:        ["Sort By #", "Title", "Artist", "BPM", "Key", "Rating", "Import Date"]
  readonly property int     selectedFooterId: (selectedFooterItem.value === undefined) ? 0 : ( ( selectedFooterItem.value % 2 === 1 ) ? 1 : 4 ) // selectedFooterItem.value takes values from 1 to 4.
  
  property          real    preSortingKnobValue: 0.0

  //--------------------------------------------------------------------------------------------------------------------  

  AppProperty { id: previewIsLoaded;     path : "app.traktor.browser.preview_player.is_loaded" }
  AppProperty { id: previewTrackLenght;  path : "app.traktor.browser.preview_content.track_length" }
  AppProperty { id: previewTrackElapsed; path : "app.traktor.browser.preview_player.elapsed_time" }

  AppProperty { id: deckAKeyDisplay; path: "app.traktor.decks.1.track.key.key_for_display" }
  AppProperty { id: deckBKeyDisplay; path: "app.traktor.decks.2.track.key.key_for_display" }
  AppProperty { id: deckCKeyDisplay; path: "app.traktor.decks.3.track.key.key_for_display" }
  AppProperty { id: deckDKeyDisplay; path: "app.traktor.decks.4.track.key.key_for_display" }

  readonly property variant deckLabels:       ["C", "A", "B", "D"]
  readonly property variant decks:            [deckCKeyDisplay, deckAKeyDisplay, deckBKeyDisplay, deckDKeyDisplay]

  MappingProperty { id: overlayState;      path: propertiesPath + ".overlay" }
  MappingProperty { id: isContentListProp; path: propertiesPath + ".browser.is_content_list" }
  MappingProperty { id: selectedFooterItem;      path: propertiesPath + ".selected_footer_item" }

  //--------------------------------------------------------------------------------------------------------------------  
  // Behavior on Sorting Chnages (show/hide sorting widget, select next allowed sorting)
  //--------------------------------------------------------------------------------------------------------------------  

  onIsContentListChanged: { 
    // We need this to be able do disable mappings (e.g. sorting ascend/descend) 
    isContentListProp.value = isContentList; 
  }

  onSortingKnobValueChanged: { 
    if (!footer.isContentList)
    return;

    overlayState.value = Overlay.sorting;
    sortingOverlayTimer.restart();

    var val = clamp(footer.sortingKnobValue - footer.preSortingKnobValue, -1, 1);
    val     = parseInt(val);
    if (val != 0) {
      qmlBrowser.sortingId   = getSortingIdWithDelta( val );
      footer.preSortingKnobValue = footer.sortingKnobValue;   
    }
  }


  Timer {
    id: sortingOverlayTimer
    interval: 800  // duration of the scrollbar opacity
    repeat:   false

    onTriggered: overlayState.value = Overlay.none;
  }


  //--------------------------------------------------------------------------------------------------------------------  
  // View
  //--------------------------------------------------------------------------------------------------------------------  

  clip: true
  anchors.left:   parent.left
  anchors.right:  parent.right
  anchors.bottom: parent.bottom
  height:         21 // set in state
  color:          "transparent"

  // background color
  Rectangle {
    id: browserFooterBg
    anchors.left:   parent.left
    anchors.right:  parent.right
    anchors.bottom: parent.bottom
    height:         17
    color:          colors.colorBrowserHeader // footer background color
  }

  Row {
    id: sortingRow
    anchors.left:   browserFooterBg.left
    anchors.leftMargin: 1
    anchors.top:  browserFooterBg.top

    Item {
      width:  120
      height: 17

      Text {
        font.pixelSize: fonts.scale(12) 
        anchors.left: parent.left
        anchors.leftMargin:     3
        font.capitalization: Font.AllUppercase
        color: selectedFooterId == 1 ? "white" : colors.colorFontBrowserHeader
        text:  getSortingNameForSortId(qmlBrowser.sortingId)
        visible: qmlBrowser.isContentList
      }
      // Arrow (Sorting Direction Indicator)
      Widgets.Triangle { 
        id : sortDirArrow
        width:  8
        height: 4
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin:  6
        anchors.rightMargin: 6
        antialiasing: false
        visible: (qmlBrowser.isContentList && qmlBrowser.sortingId > 0)
        color: colors.colorGrey80
        rotation: ((qmlBrowser.sortingDirection == 1) ? 0 : 180) 
      }
      Rectangle {
        id: divider
        height: 15
        width: 1
        color: colors.colorGrey40 // footer divider color
        anchors.right: parent.right
      }
    }

    Repeater {
      model: 4

      Item {
        width:  60
        height: 17
        Text {
          font.pixelSize: fonts.scale(12) 
          anchors.left:   parent.left
          anchors.leftMargin: 0
//          font.capitalization: Font.AllUppercase
          color: (index == 1 || index == 2) ? colors.colorDeckBlueBright : colors.colorWhite //colors.colorFontBrowserHeader
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: deckLabels[index] + ": " + convertToCamelot(decks[index].value)
        }

        Rectangle {
          id: divider
          height: 15
          width: 1
          color: colors.colorGrey40 // footer divider color
          anchors.right: parent.right
        }
      }
    }

    // Preview Player footer
    Item {
      width:  120
      height: 17

      Text {
        font.pixelSize: fonts.scale(12) 
        anchors.left: parent.left
        anchors.leftMargin: 5
        font.capitalization: Font.AllUppercase
        color: selectedFooterId == 4 ? "white" : colors.colorFontBrowserHeader
        text: "Preview"
      }

      Image {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin:     2
        anchors.rightMargin:  45
        visible: previewIsLoaded.value
        antialiasing: false
        source: "./../images/PreviewIcon_Small.png"
        fillMode: Image.Pad
        clip: true
        cache: false
        sourceSize.width: width
        sourceSize.height: height
      }
      Text {
        width: 40
        clip: true
        horizontalAlignment: Text.AlignRight
        visible: previewIsLoaded.value
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin:     2
        anchors.rightMargin:  7
        font.pixelSize: fonts.scale(12)
        font.capitalization: Font.AllUppercase
        font.family: "Pragmatica"
        color: colors.browser.prelisten
        text: utils.convertToTimeString(previewTrackElapsed.value)
      }
    }
  }

  //--------------------------------------------------------------------------------------------------------------------  
  // black border & shadow
  //--------------------------------------------------------------------------------------------------------------------  

  Rectangle {    
    id: browserHeaderBottomGradient
    height:         3
    anchors.left:   parent.left
    anchors.right:  parent.right
    anchors.bottom: browserHeaderBlackBottomLine.top
    gradient: Gradient {
      GradientStop { position: 0.0; color: colors.colorBlack0 }
      GradientStop { position: 1.0; color: colors.colorBlack38 }
    }
  }

  Rectangle {
    id: browserHeaderBlackBottomLine
    height:         2
    color:          colors.colorBlack
    anchors.left:   parent.left
    anchors.right:  parent.right
    anchors.bottom: browserFooterBg.top
  }

  //------------------------------------------------------------------------------------------------------------------

  state: "show"  
  states: [
  State {
    name: "show"
    PropertyChanges{ target: footer; height: 21 }
    },
    State {
      name: "hide"
      PropertyChanges{ target: footer; height: 0 }
    }
    ]


    //--------------------------------------------------------------------------------------------------------------------  
    // Necessary Functions
    //--------------------------------------------------------------------------------------------------------------------  

  function convertToCamelot(keyToConvert)
  {
    if (keyToConvert == "") return "-";

    switch(keyToConvert)
    {
      case "1d" : return "8B";
      case "2d" : return "9B";
      case "3d" : return "10B";
      case "4d" : return "11B";
      case "5d" : return "12B";
      case "6d" : return "1B";
      case "7d" : return "2B";
      case "8d" : return "3B";
      case "9d" : return "4B";
      case "10d" : return "5B";
      case "11d" : return "6B";
      case "12d" : return "7B";
      case "1m" : return "8A";
      case "2m" : return "9A";
      case "3m" : return "10A";
      case "4m" : return "11A";
      case "5m" : return "12A";
      case "6m" : return "1A";
      case "7m" : return "2A";
      case "8m" : return "3A";
      case "9m" : return "4A";
      case "10m" : return "5A";
      case "11m" : return "6A";
      case "12m" : return "7A";
    }
    return "ERR";
  }

    function getSortingIdWithDelta( delta ) 
    {
      var curPos = getPosForSortId( qmlBrowser.sortingId );
      var pos    = curPos + delta;
      var count  = sortIds.length;

      pos = (pos < 0)      ? count-1 : pos;
      pos = (pos >= count) ? 0       : pos;

      return sortIds[pos];
    }


    function getPosForSortId(id) {
      if (id == -1) return 0; // -1 is a special case which should be interpreted as "0"
      for (var i=0; i<sortIds.length; i++) {
        if (sortIds[i] == id) return i;
      }
      return -1;
    }


    function getSortingNameForSortId(id) {
      var pos = getPosForSortId(id);
      if (pos >= 0 && pos < sortNames.length)
      return sortNames[pos];
      return "SORTED";
    }


    function clamp(val, min, max){
      return Math.max( Math.min(val, max) , min );
    }

  }
