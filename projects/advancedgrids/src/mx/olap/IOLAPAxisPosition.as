
package mx.olap
{
import mx.collections.IList;

/**
 *  The IOLAPAxisPosition interface represents a position on an OLAP axis.
 *.
 *  @see mx.olap.OLAPQueryAxis
 *  @see mx.olap.OLAPResultAxis
 *  
 *  @langversion 3.0
 *  @playerversion Flash 9
 *  @playerversion AIR 1.1
 *  @productversion Flex 3
 */
public interface IOLAPAxisPosition
{
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  members
	//----------------------------------
	
    /**
     * The members for this position, as a list of IOLAPMember instances.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    function get members():IList; //(of IOLAPMemeber)
}
}