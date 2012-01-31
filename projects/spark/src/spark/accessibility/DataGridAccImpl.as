////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2010 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package spark.accessibility
{

import flash.accessibility.Accessibility;
import flash.events.Event;
import mx.accessibility.AccConst;
import mx.collections.IList;
import mx.core.UIComponent;
import mx.core.mx_internal;
import mx.resources.ResourceManager;
import mx.resources.IResourceManager;
import spark.components.DataGrid;
import spark.components.Grid;
import spark.components.gridClasses.GridSelectionMode;
import spark.components.gridClasses.CellPosition;
import spark.events.GridEvent;
import spark.events.GridCaretEvent;
import spark.events.GridSelectionEvent;
import spark.events.GridSelectionEventKind;
import spark.skins.spark.DefaultGridItemRenderer;

use namespace mx_internal;

/**
 *  DataGridAccImpl is a subclass of AccessibilityImplementation
 *  which implements accessibility for the DataGrid class.
 *
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class DataGridAccImpl extends ListBaseAccImpl
{
    include "../core/Version.as";

    // See the DataGridAccImpl constructor for why this is not initialized here.
    private static var dgAccInfo:ItemAccInfo; // = new ItemAccInfo();

    //--------------------------------------------------------------------------
    //
    //  Class methods
    //
    //--------------------------------------------------------------------------

    /**
     *  Enables accessibility in the DataGrid class.
     *
     *  <p>This method is called by application startup code
     *  that is autogenerated by the MXML compiler.
     *  Afterwards, when instances of DataGrid are initialized,
     *  their <code>accessibilityImplementation</code> property
     *  will be set to an instance of this class.</p>
     *
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public static function enableAccessibility():void
    {
        DataGrid.createAccessibilityImplementation =
            createAccessibilityImplementation;
    }

    /**
     *  @private
     *  Creates a DataGrid's AccessibilityImplementation object.
     *  This method is called from UIComponent's
     *  initializeAccessibility() method.
     */
    mx_internal static function createAccessibilityImplementation(
                                component:UIComponent):void
    {
        component.accessibilityImplementation =
            new DataGridAccImpl(component);
    }

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor.
     *
     *  @param master The UIComponent instance that this AccImpl instance
     *  is making accessible.
     *
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function DataGridAccImpl(master:UIComponent)
    {
        super(master);
        // Normally this would not be done here, but at this writing,
        // initializing dgAccInfo from its declaration line causes an RTE,
        // apparently because the AS compiler does not yet detect a forward-ref
        // problem that results in an incorrect initialization at run time.
        // [DGL, 2010-09-07]
        if (!dgAccInfo)
            dgAccInfo = new ItemAccInfo();
    }

    //--------------------------------------------------------------------------
    //
    //  Overridden properties: AccImpl
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  eventsToHandle
    //----------------------------------

    /**
     *  @private
     *  Array of events that we should listen for from the master component.
     */
    override protected function get eventsToHandle():Array
    {
        return super.eventsToHandle.concat([GridSelectionEvent.SELECTION_CHANGE]);
    }

    //--------------------------------------------------------------------------
    //
    //  Overridden methods: AccessibilityImplementation
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     *  Gets the role for the component.
     *
     *  @param childID Children of the component
     */
    override public function get_accRole(childID:uint):uint
    {
        if (childID == 0)
            // Get this out of the way quick; it's often requested by AT.
            return role;
        dgAccInfo.setup(master, childID);
        if (dgAccInfo.isInvalid || !dgAccInfo.dataGrid.columns)
            return null;

        if (dgAccInfo.isColumnHeader)
            return AccConst.ROLE_SYSTEM_COLUMNHEADER;
        else
            // Same role for all childIDs regardless of mode (row or cell).
            // Valid and invalid childIDs return this;
            // this behavior is common to most list-based controls we've seen.
            // [DGL, 2010-08-10]
            return AccConst.ROLE_SYSTEM_LISTITEM;
    }

    /**
     *  @private
     *  IAccessible method for returning the state of the GridItem.
     *  States are predefined for all the components in MSAA.
     *  Values are assigned to each state.
     *  Depending upon the GridItem being Selected, Selectable, Invisible,
     *  Offscreen, a value is returned.
     *
     *  @param childID uint
     *
     *  @return State uint
     */
    override public function get_accState(childID:uint):uint
    {
        var accState:uint = getState(childID);
        if (int(childID) <= 0)
            return accState;

        dgAccInfo.setup(master, childID);
        if (!dgAccInfo.dataGrid.columns)
            return accState;
        if (dgAccInfo.isInvalid)
            // Child ID out of bounds most likely.
            return accState;
        if (dgAccInfo.isColumnHeader)
        {
            // isColumnHeader implies columnHeaderGroup.visible is true.
            // The below code remains in case it is ever decided to
            // make invisible but present headerBars show up with childIDs.
            /*
            if (dgAccInfo.dataGrid.columnHeaderGroup
            && !dgAccInfo.dataGrid.columnHeaderGroup.visible)
                accState |= AccConst.STATE_SYSTEM_INVISIBLE;
            */
            if (dgAccInfo.dataGrid.columnHeaderGroup
            && !dgAccInfo.dataGrid.columnHeaderGroup.getHeaderRendererAt(childID-1).visible)
                accState |= AccConst.STATE_SYSTEM_OFFSCREEN;
            // There are some states we don't allow for these.
            return accState & ~(
                AccConst.STATE_SYSTEM_FOCUSABLE
                | AccConst.STATE_SYSTEM_SELECTABLE
                | AccConst.STATE_SYSTEM_FOCUSED
                | AccConst.STATE_SYSTEM_SELECTED
            );
        }

        // We now have only rows and data cells to consider.

        // Determine if this item is focused.
        if (childID == get_accFocus())
            accState |= AccConst.STATE_SYSTEM_FOCUSED;

        // Must recalculate dgAccInfo here because get_accFocus() changed it.
        dgAccInfo.setup(master, childID);

        // Anything (row or cell) is selectable unless selection is not allowed at all.
        var mode:String = dgAccInfo.dataGrid.selectionMode;
        if (mode != GridSelectionMode.NONE)
        {
            accState |= AccConst.STATE_SYSTEM_SELECTABLE;
            if (dgAccInfo.isMultiSelect)
            {
                accState |= AccConst.STATE_SYSTEM_MULTISELECTABLE;
            }
        }

        // Figure out selectedness.
        var isSelected:Boolean;
        if (dgAccInfo.isCellMode)
            isSelected = dgAccInfo.dataGrid.selectionContainsCell(
                dgAccInfo.rowIndex,
                dgAccInfo.columnIndex
            );
        else
            isSelected = dgAccInfo.dataGrid.selectionContainsIndex(
                dgAccInfo.rowIndex
            );
        if (isSelected)
            accState |= AccConst.STATE_SYSTEM_SELECTED;

        // Figure out visibility and offscreenness.
        var rowIndex:int = dgAccInfo.rowIndex;
        var columnIndex:int = dgAccInfo.columnIndex;
        if (!dgAccInfo.isCellMode)
            columnIndex = -1;
        if (!dgAccInfo.dataGrid.grid.isCellVisible(rowIndex, columnIndex))
            accState |= AccConst.STATE_SYSTEM_OFFSCREEN

        return accState;
    }

    /**
     *  @private
     *  IAccessible method for returning the Default Action.
     *
     *  @param childID uint
     *
     *  @return DefaultAction String
     */
    override public function get_accDefaultAction(childID:uint):String
    {
        if (get_accRole(childID) == AccConst.ROLE_SYSTEM_COLUMNHEADER)
            return "Click";;
        return super.get_accDefaultAction(childID);
    }

    /**
     *  @private
     *  IAccessible method for executing the Default Action.
     *
     *  @param childID uint
     */
    override public function accDoDefaultAction(childID:uint):void
    {
        dgAccInfo.setup(master, childID);
        if (!dgAccInfo.dataGrid.columns || dgAccInfo.isInvalid)
            return;

        if (dgAccInfo.isColumnHeader)
        {
            // TODO: Allow doDefaultAction to sort columns
            return;
        }

        // TODO: Allow doDefaultAction to go into edit mode if editable
        accSelect(AccConst.SELFLAG_TAKESELECTION | AccConst.SELFLAG_TAKEFOCUS, childID);
    }

    /**
     *  @private
     *  Method to return an array of childIDs.
     *
     *  @return Array
     */
    override public function getChildIDArray():Array
    {
        dgAccInfo.setup(master, 0);
        if (!dgAccInfo.dataGrid.columns)
            return null;
        return createChildIDArray(dgAccInfo.maxChildID);
    }

    /**
     *  @private
     *  IAccessible method for returning the bounding box of the GridItem.
     *
     *  @param childID uint
     *
     *  @return Location Object
     */
    override public function accLocation(childID:uint):*
    {
        dgAccInfo.setup(master, childID);
        if (!dgAccInfo.dataGrid.columns)
            return null;
        if (dgAccInfo.isInvalid)
            return null;
        return dgAccInfo.boundingRect();
    }

    /**
     *  @private
     *  IAccessible method for returning the childFocus of the DataGrid.
     *
     *  @param childID uint
     *
     *  @return focused childID.
     */
    override public function get_accFocus():uint
    {
        dgAccInfo.setup(master, 0);
        if (!dgAccInfo.dataGrid.columns || !dgAccInfo.dataGrid.dataProvider)
            return null;

        // TODO: handle editable

        return dgAccInfo.childIDFromRowAndColumn(
            dgAccInfo.dataGrid.grid.caretRowIndex,
            dgAccInfo.dataGrid.grid.caretColumnIndex
        );
    }

    //--------------------------------------------------------------------------
    //
    //  Overridden methods: AccImpl
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     *  method for returning the name of the ListItem/DataGrid
     *  which is spoken out by the screen reader
     *  The ListItem should return the label as the name with m of n string and
     *  DataGrid should return the name specified in the AccessibilityProperties.
     *
     *  @param childID uint
     *
     *  @return Name String
     */
    override protected function getName(childID:uint):String
    {
        if (int(childID) <= 0)
            return null;
        dgAccInfo.setup(master, childID);
        if (dgAccInfo.isInvalid || !dgAccInfo.dataGrid.columns)
            return null;
        if (dgAccInfo.isColumnHeader)
            return dgAccInfo.dataGrid.columns.getItemAt(childID-1).headerText;
        if (!dgAccInfo.dataGrid.dataProvider)
            return null;

        // We now have only rows and data cells to consider.

        // String representation of row position.
        var rowString:String = "";
        if ((dgAccInfo.isCellMode && dgAccInfo.columnIndex == 0) || !dgAccInfo.isCellMode)
        {
            var resourceManager:IResourceManager = ResourceManager.getInstance();
            rowString = resourceManager.getString("components", "rowMofN");
            rowString = rowString.replace("%1", dgAccInfo.rowIndex + 1).replace("%2", dgAccInfo.rowCount);
        }

        // Construct the name to return.
        var name:String = "";
        // TODO: Should the types of these be more specific?
        var rowObject:Object = dgAccInfo.dataGrid.dataProvider.getItemAt(dgAccInfo.rowIndex);
        var columns:IList = dgAccInfo.dataGrid.columns;
        if (dgAccInfo.isCellMode)
        {
            if (dgAccInfo.headerCount > 0)
                name = columns.getItemAt(dgAccInfo.columnIndex).headerText + ": "
            name += cellName(rowObject, dgAccInfo.columnIndex);
        }
        else if (rowObject)  // row mode
        {
            for (var c:int = 0; c < dgAccInfo.columnCount; c++)
            {
                if (c > 0)
                    name += ", ";
                if (dgAccInfo.headerCount > 0)
                    name += columns.getItemAt(c).headerText + ": ";
                name += columns.getItemAt(c).itemToLabel(rowObject);
            }
        }  // cell or row mode
        if (rowString)
            name += ", " +rowString;

        return name;
    }

    /**
     *  @private
     *  IAccessible method for focusing an item or altering selection.
     * This is a full implementation based on the Microsoft Active Accessibility
     * (MSAA) specification.
     *
     * @param selFlag:uint A combination of flags indicating what to do.
     * Flags may be combined as indicated below:
     * <dl>
     * <dt><code>SELFLAG_TAKEFOCUS</code>
     * <dd>Set focus to the childID given.
     * May be combined with the below flags.
     * <dt><code>SELFLAG_TAKESELECTION</code>
     * <dd>Select the given child and unselect any other selected ones.
     * Combining this with <code>SELFLAG_TAKEFOCUS</code>
     * emulates a single mouse click.
     * <dt><code>SELFLAG_ADDSELECTION</code>
     * <dd>Add the given child to those that are selected.
     * Combining this with <code>SELFLAG_TAKEFOCUS</code>
     * emulates a mouse click on an unselected item with the <kbd>Ctrl</kbd> key down.
     * <dt><code>SELFLAG_REMOVESELECTION</code>
     * <dd>Remove the given child from those that are selected.
     * Combining this with <code>SELFLAG_TAKEFOCUS</code>
     * emulates a mouse click on a selected item with the <kbd>Ctrl</kbd> key down.
     * <dt><code>SELFLAG_ADDSELECTION | SELFLAG_EXTENDSELECTION</code>
     * <dd>Select all children from the current focus to the given child.
     * <dt><code>SELFLAG_REMOVESELECTION | SELFLAG_EXTENDSELECTION</code>
     * <dd>Unselect all children from the current focus to the given child.
     * <dt><code>SELFLAG_EXTENDSELECTION</code>
     * <dd>Duplicate the selected/unselected state of the currently focused child,
     * for all children through the given child.
     * Combining this with <code>SELFLAG_TAKEFOCUS</code>
     * emulates a mouse click with the <kbd>Shift</kbd> key down.
     * </dl>
     *  @param childID uint The ID of the child to use.
     * For extending selection or unselection, this is the endpoint,
     * and current focus is the anchor.
     */
    override public function accSelect(selFlag:uint, childID:uint):void
    {
        dgAccInfo.setup(master, childID);
        if (dgAccInfo.isColumnHeader || dgAccInfo.isInvalid)
            return;

        // TODO: Adjust for there being no apparent way to just set focus
        // without altering selection:  For now, treate SELFLAG_TAKEFOCUS like
        // SELFLAG_TAKESELECTION, and remove the TAKEFOCUS bit from
        // all other requests, thus letting other selection calls also
        // handle focus changes.
        // Code for handling focus properly remains below in case a
        // way is found to make the code at the end of this function
        // actually set focus independent of selection.
        if (selFlag == AccConst.SELFLAG_TAKEFOCUS)
            selFlag = AccConst.SELFLAG_TAKESELECTION
        else if (selFlag & AccConst.SELFLAG_TAKEFOCUS)
            selFlag -= AccConst.SELFLAG_TAKEFOCUS

        var settingFocus:Boolean = Boolean(selFlag & AccConst.SELFLAG_TAKEFOCUS);
        if (settingFocus)
            selFlag -= AccConst.SELFLAG_TAKEFOCUS;

        var rowIndex:int = dgAccInfo.rowIndex;
        var columnIndex:int = dgAccInfo.columnIndex;
        if (!dgAccInfo.isCellMode)
            columnIndex = -1;
        var grid:DataGrid = dgAccInfo.dataGrid;
        grid.ensureCellIsVisible(rowIndex, columnIndex);

        // First selection, then focus if requested.
        // Caveat: Invalid selection flags will cause no changes to be made,
        // including a focus change if one was requested.

        if (selFlag == AccConst.SELFLAG_TAKESELECTION)
        {
            if (columnIndex == -1)
                grid.setSelectedIndex(rowIndex);
            else
                grid.setSelectedCell(rowIndex, columnIndex);
        }
        else if (selFlag == AccConst.SELFLAG_ADDSELECTION)
        {
            if (columnIndex == -1)
                grid.addSelectedIndex(rowIndex);
            else
                grid.addSelectedCell(rowIndex, columnIndex);
        }
        else if (selFlag == AccConst.SELFLAG_REMOVESELECTION)
        {
            if (columnIndex == -1)
                grid.removeSelectedIndex(rowIndex);
            else
                grid.removeSelectedCell(rowIndex, columnIndex);
        }
        else if (Boolean(selFlag & AccConst.SELFLAG_EXTENDSELECTION))
        {
            if (Boolean(selFlag & AccConst.SELFLAG_ADDSELECTION)
            && Boolean(selFlag & AccConst.SELFLAG_REMOVESELECTION))
                return;
            var focusedID:uint = get_accFocus();
            if (!focusedID)
            {
                // This could be assumed to be 1, but this is probably safer.
                return;
            }
            // We have to recalculate dgAccInfo for the anchor,
            // but we already have row/column indices for the requested item,
            // so we can do that without needing to reset it again afterward.
            dgAccInfo.setup(master, focusedID);
            if (dgAccInfo.isColumnHeader || dgAccInfo.isInvalid)
                return;
            var anchorRowIndex:int = dgAccInfo.rowIndex;
            var anchorColumnIndex:int = dgAccInfo.columnIndex;
            var adding:Boolean;
            if (Boolean(selFlag & AccConst.SELFLAG_ADDSELECTION))
                adding = true;
            else if (Boolean(selFlag & AccConst.SELFLAG_REMOVESELECTION))
                adding = false;
            else
            {
                // MSAA docs say use selection state of anchor here.
                // This method of figuring that out is a bit more
                // intensive than necessary (other states calculated also),
                // but selection extension without ADD/REMOVE being specified
                // should be a very infrequent occurrence, and this method
                // centralizes the logic for figuring out what is selected.
                adding = Boolean(get_accState(focusedID) & AccConst.STATE_SYSTEM_SELECTED);
            }
            if (columnIndex == -1)
                grid.selectIndices(
                    Math.min(anchorRowIndex, rowIndex),
                    Math.abs(rowIndex - anchorRowIndex) + 1
                );
            else
                grid.selectCellRegion(
                    Math.min(anchorRowIndex, rowIndex),
                    Math.min(anchorColumnIndex, columnIndex),
                    Math.abs(rowIndex - anchorRowIndex) + 1,
                    Math.abs(columnIndex - anchorColumnIndex) + 1
                );
        }

        // Now handle the focus change request if there was one
        // (and if invalid flags didn't cause a return above).
        // TODO:  This approach does not work properly, and to date,
        // no approach that does has been found.
        // Code at the top of this function effectively makes the
        // below "if" never true.
        if (settingFocus)
            grid.grid.caretRowIndex = rowIndex;
            grid.grid.caretColumnIndex = columnIndex;
    }

    /**
     *  @private
     *  IAccessible method for returning the child Selections in the List.
     *
     *  @param childID uint
     *
     *  @return focused childID.
     */
    override public function get_accSelection():Array
    {
        var accSelection:Array = [];
        dgAccInfo.setup(master, 0);
        if (!dgAccInfo.dataGrid.columns)
            return null;
        var i:int
        var n:int
        var items:Object;

        if (dgAccInfo.isCellMode)
        {
            items = dgAccInfo.dataGrid.selectedCells;
            n = items.length;
            for (i = 0; i < n; i++)
            {
                // The selected childID is effectively the 1-based cell index.
                // This is row*colCount + columnInRow +columnHeaderCount +1.
                accSelection[i] = items[i].rowIndex * dgAccInfo.columnCount
                + items[i].columnIndex
                + dgAccInfo.headerCount + 1;
            }
        }
        else // row mode
        {
            items = dgAccInfo.dataGrid.selectedIndices;
            n = items.length;
            for (i = 0; i < n; i++)
            {
                // This time we just need rowIndex (0-based) + headerCount + 1.
                accSelection[i] = items[i] + dgAccInfo.headerCount + 1;
            }

        }

        return accSelection;

    }

    //--------------------------------------------------------------------------
    //
    //  Overridden event handlers: AccImpl
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     *  Override the generic event handler.
     *  All AccImpl must implement this to listen
     *  for events from its master component.
     */
    override protected function eventHandler(event:Event):void
    {
        // Let AccImpl class handle the events
        // that all accessible UIComponents understand.
        $eventHandler(event);

        dgAccInfo.setup(master, 0);
        if (!dgAccInfo.dataGrid.columns)
            return;

        var childID:uint;
        switch (event.type)
        {
            case GridCaretEvent.CARET_CHANGE:
            {
                childID = dgAccInfo.childIDFromRowAndColumn(
                    int(GridCaretEvent(event).newRowIndex),
                    int(GridCaretEvent(event).newColumnIndex)
                );
                if (int(childID) > 0)
                    Accessibility.sendEvent(dgAccInfo.dataGrid, childID, AccConst.EVENT_OBJECT_FOCUS);
                break;
            }
            case GridSelectionEvent.SELECTION_CHANGE:
            {
                var gridSelectionEvent:GridSelectionEvent = GridSelectionEvent(event);
                childID = dgAccInfo.childIDFromRowAndColumn(
                    gridSelectionEvent.selectionChange.rowIndex,
                    gridSelectionEvent.selectionChange.columnIndex
                );
                if (int(childID) <= 0)
                    return;

                var eventID:int = AccConst.EVENT_OBJECT_SELECTION;
                var kind:String = gridSelectionEvent.kind;
                if (kind == GridSelectionEventKind.ADD_CELL
                || kind == GridSelectionEventKind.ADD_ROW)
                    eventID = AccConst.EVENT_OBJECT_SELECTIONADD;
                else if (kind == GridSelectionEventKind.REMOVE_CELL
                || kind == GridSelectionEventKind.REMOVE_ROW)
                    eventID = AccConst.EVENT_OBJECT_SELECTIONREMOVE;
                else if (kind == GridSelectionEventKind.CLEAR_SELECTION
                || kind == GridSelectionEventKind.SELECT_ALL
                || kind == GridSelectionEventKind.SET_CELL_REGION
                || kind == GridSelectionEventKind.SET_ROWS)
                    eventID = AccConst.EVENT_OBJECT_SELECTIONWITHIN;

                Accessibility.sendEvent(dgAccInfo.dataGrid, childID, eventID);
                break;
            }
        }
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    private function cellName(rowObject:Object, columnIndex:int):String
    {
        var item:Object = rowObject;
        if (item is String)
            return "" + item;
        var dataGrid:DataGrid = DataGrid(master);
        var columns:IList = dataGrid.columns;
        if (!columns)
            return null;
        var column:Object = columns.getItemAt(columnIndex);
        if (!column)
            return null;
        return column.itemToLabel(rowObject);
    }

}

}

internal class ItemAccInfo
{
    import mx.core.UIComponent;
    import spark.components.DataGrid;
    import spark.components.Grid;
    import spark.components.gridClasses.GridSelectionMode;
    import spark.components.gridClasses.CellPosition;
    import flash.geom.Rectangle;
    import flash.geom.Point;

    /**
     *  Constructor.
     */
    public function ItemAccInfo()
    {
        super();
    }

    /**
     *
     *  @param master The UIComponent instance that this AccImpl instance
     *  is making accessible.
     *  @param childID The childID of the item of interest.
     */
    public function setup(master:UIComponent, childID:uint):void
    {
        this.master = master;
        this.childID = childID;
        dataGrid = DataGrid(master);
        visibleRowIndices = null;
        visibleColumnIndices = null;
        if (dataGrid.columns)
        {
            columnCount = dataGrid.columns.length;
            visibleColumnCount = visibleColumnIndices == null ?
                columnCount : visibleColumnIndices.length;
        }
        else
        {
            columnCount = 0;
            visibleColumnCount = 0;
        }
        if (dataGrid.dataProvider)
        {
          rowCount = dataGrid.dataProvider.length;
            visibleRowCount = visibleRowIndices == null ?
                rowCount : visibleRowIndices.length;
        }
        else
        {
            rowCount = 0;
            visibleRowCount = 0;
        }
        headerCount = 0;
        visibleHeaderCount = 0;
        maxChildID = 0;
        isCellMode = false;
        isMultiSelect = false;
        isInvalid = false;
        isColumnHeader = false;
        rowIndex = 0;
        columnIndex = 0;
        visibleRowIndex = 0;
        visibleColumnIndex = 0;

        var itemIndex:int = childID - 1;
        if (dataGrid.columnHeaderGroup && dataGrid.columnHeaderGroup.visible)
        {
            // There are visible column headers, so their childIDs come first.
            itemIndex -= visibleColumnCount;
            headerCount = columnCount;
            visibleHeaderCount = visibleColumnCount;
        }
        else
        {
            // No header bar or it's invisible,
            // so we should not try to expose any data within it.
            headerCount = 0;
            visibleHeaderCount = 0;
        }
        var mode:String = dataGrid.selectionMode;
        isCellMode = (
            mode == GridSelectionMode.SINGLE_CELL
            || mode == GridSelectionMode.MULTIPLE_CELLS
        );
        isMultiSelect = (
            mode == GridSelectionMode.MULTIPLE_CELLS
            || mode == GridSelectionMode.MULTIPLE_ROWS
        );
        maxChildID = 0;
        // Account for visible headers.
        maxChildID += visibleHeaderCount;
        // Then for visible cells or rows as appropriate.
        if (isCellMode)
            maxChildID += visibleRowCount * visibleColumnCount;
        else
            maxChildID += visibleRowCount;
        isColumnHeader = false;
        isInvalid = false;
        if (childIDOutOfBounds(childID))
        {
            isInvalid = true;
            visibleColumnIndex = -1;
            visibleRowIndex = -1;
            itemIndex = -1;
        }
        else if (itemIndex < 0)
        {
            // This childID refers to a header, not a data row or cell.
            isColumnHeader = true;
            visibleColumnIndex = itemIndex + visibleColumnCount;
            visibleRowIndex = -1;
            itemIndex = -1;
        }
        else if (isCellMode)
        {
            visibleRowIndex = Math.floor(itemIndex / visibleColumnCount);
            visibleColumnIndex = itemIndex % visibleColumnCount;
        }
        else
        {
            visibleRowIndex = itemIndex;
            // Using 0 here so, for example, getItemRendererAt() calls still work for a row.
            visibleColumnIndex = 0;
        }
        rowIndex = visibleRowIndex;
        columnIndex = visibleColumnIndex;
        if (visibleRowIndex >= 0 && visibleRowIndices != null)
            rowIndex = visibleRowIndices[visibleRowIndex];
        if (visibleColumnIndex >= 0 && visibleColumnIndices != null)
            columnIndex = visibleColumnIndices[visibleColumnIndex];
    }

    // The master component reference for which this AccImpl is instantiated.
    public var master:UIComponent;
    // The childID within that component for which this accInfo is calculated.
    public var childID:uint;
    // The DataGrid reference for this instance.
    public var dataGrid:DataGrid;
    // Number of columns, headers, and rows overall.
    public var columnCount:int;
    public var headerCount:int;
    public var rowCount:int;
    // Number of columns, headers, and rows that are visible.
    // ("Visible" means not marked invisible by programmer or user.)
    public var visibleColumnCount:int;
    public var visibleHeaderCount:int;
    public var visibleRowCount:int;
    // Indices of visible rows and columns.
    // These are null when nothing is filtered, for performance reasons.
    protected var visibleRowIndices:Vector.<int>;
    protected var visibleColumnIndices:Vector.<int>;
    // The highest valid childID.
    public var maxChildID:int;
    // True if we are in cell navigation mode (single or multiple selection).
    public var isCellMode:Boolean;
    // True if we are in a multiple selection mode (row or cell).
    public var isMultiSelect:Boolean;
    // True if the data in this object is invalid for some reason.
    // Usually this means an invalid childID was passed to setup().
    public var isInvalid:Boolean;
    // True if the given childID represents a column header cell.
    public var isColumnHeader:Boolean;
    // 0-based indices of row and column in the sets of visible ones.
    public var visibleColumnIndex:int;
    public var visibleRowIndex:int;
    // 0-based indices of row and column in the set of all of each.
    public var columnIndex:int;
    public var rowIndex:int;

    private function childIDFromVisibleRowAndColumn(visibleRowIndex:int, visibleColumnIndex:int):uint
    {
        var childID:int = visibleHeaderCount + 1;
        if (visibleRowIndex < 0)
            childID = 0;
        else if (isCellMode)
            if (visibleColumnIndex < 0)
                childID = 0;
            else
                childID += visibleRowIndex * visibleColumnCount + visibleColumnIndex;
        else
            childID += visibleRowIndex;
        return uint(childID);
    }

    public function childIDFromRowAndColumn(rowIndex:int, columnIndex:int):uint
    {
        return childIDFromVisibleRowAndColumn(
            visibleRowIndices == null ? rowIndex : visibleRowIndices.indexOf(rowIndex),
            visibleColumnIndices == null ? columnIndex : visibleColumnIndices.indexOf(columnIndex)
        );
    }

    private function childIDOutOfBounds(childID: int):Boolean
    {
        if (int(childID) <= 0)
            return true;
        if (!dataGrid.dataProvider || !dataGrid.columns)
            return true
        if (childID > maxChildID)
            return true;
        return false;
    }

    public function boundingRect():Object
    {
        // First see if this item is on screen.
        // We could skip this, but we'd run the risk of having
        // assistive technology create huge numbers of itemRenderers below
        // by quickly scanning an entire grid.
        if (!isColumnHeader && (rowIndex < 0 || rowIndex >= rowCount))
            // Also covers rowCount == 0 effectively.
            return null;
        if (isCellMode && (columnIndex < 0 || columnIndex >= columnCount))
            return null;
        var vri:Vector.<int> = dataGrid.grid.getVisibleRowIndices();
        var vci:Vector.<int> = dataGrid.grid.getVisibleColumnIndices();
        if (isColumnHeader && vci.indexOf(columnIndex) < 0)
            return null;
        if ((!isColumnHeader && vri.indexOf(rowIndex) < 0)
        || (isCellMode && vci.indexOf(columnIndex) < 0))
            return null;

        var result:Object;
        if (isColumnHeader)
        {
            result = dataGrid.columnHeaderGroup.getHeaderRendererAt(columnIndex);
        }
        else if (isCellMode)
        {
            result = dataGrid.grid.getItemRendererAt(rowIndex, columnIndex);
        }
        else  // row mode
        {
            // Use the item renderers at both ends of this row
            // to calculate the width.
            // We assume here that top and bottom of all renderers for one row are equal.
            var r1:Object = dataGrid.grid.getItemRendererAt(rowIndex, vci[0]);
            var r2:Object = dataGrid.grid.getItemRendererAt(rowIndex, vci[vci.length-1]);
            var xy:Point = new Point(
                r1.getLayoutBoundsX(),
                r1.getLayoutBoundsY()
            );
            xy = dataGrid.grid.localToGlobal(xy);
            xy = dataGrid.globalToLocal(xy);
            result = new Rectangle(
                xy.x, xy.y,
                r2.getLayoutBoundsX() + r2.getLayoutBoundsWidth() - r1.getLayoutBoundsX(),
                r1.getLayoutBoundsHeight()
            );
        }
        return result;
    }

}
