/**
 * Provides an interface for animation node classes that hold animation data for use in the UV animator class.
 *
 * @see away3d.animators.UVAnimator
 */
package away3d.animators.states;


import away3d.animators.data.UVAnimationFrame;
interface IUVAnimationState extends IAnimationState {
    var currentUVFrame(get, never):UVAnimationFrame;
    var nextUVFrame(get, never):UVAnimationFrame;
    var blendWeight(get, never):Float;

    /**
	 * Returns the current UV frame of animation in the clip based on the internal playhead position.
	 */
    private function get_currentUVFrame():UVAnimationFrame;
    /**
	 * Returns the next UV frame of animation in the clip based on the internal playhead position.
	 */
    private function get_nextUVFrame():UVAnimationFrame;
    /**
	 * Returns a fractional value between 0 and 1 representing the blending ratio of the current playhead position
	 * between the current uv frame (0) and next uv frame (1) of the animation.
	 */
    private function get_blendWeight():Float;
}

