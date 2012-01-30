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

package spark.core.managers
{
    
/**
 *  IPersistenceManager defines the interface that all persistence
 *  managers must follow.  These objects are responsible for
 *  persisting data between application sessions.
 * 
 *  @see spark.core.managers.PersistenceManager
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10.1
 *  @playerversion AIR 2.5
 *  @productversion Flex 4.5
 */ 
public interface IPersistenceManager
{
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  enabled
    //----------------------------------
    
    /**
     *  Flag indicates whether the manager is enabled.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    function get enabled():Boolean;
    
    // TODO (chiedozi): Remove this property, it's not useful
    /**
     * @private
     */
    function set enabled(value:Boolean):void;
    
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Clears all the data that is being stored by the persistence
     *  manager.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    function clear():void;
    
    /**
     *  Flushes the data being managed by the persistence manager to
     *  disk or another external storage file.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    function flush():void;
    
    /**
     *  Initializes the persistence manager.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    function initialize():void;
    
    /**
     *  Returns the value of a property stored in the persistence manager.
     *  
     *  @param key The property key
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    function getProperty(key:String):Object;
    
    /**
     *  Stores a value in the persistence manager.
     * 
     *  @param key The key to use to store the value
     *  @param value The value object to store
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */ 
    function setProperty(key:String, value:Object):void;
}
}