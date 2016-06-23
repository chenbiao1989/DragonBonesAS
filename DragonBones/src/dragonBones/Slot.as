﻿package dragonBones
{
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
	import dragonBones.core.DragonBones;
	import dragonBones.core.TransformObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.MeshData;
	import dragonBones.objects.SlotDisplayDataSet;
	import dragonBones.objects.SlotTimelineData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 插槽，附着在骨骼上，控制显示对象的显示状态和属性。
     * 一个骨骼上可以包含多个插槽。
     * 一个插槽中可以包含多个显示对象，同一时间只能显示其中的一个显示对象，但可以在动画播放的过程中切换显示对象实现帧动画。
     * 显示对象可以是普通的图片纹理，也可以是子骨架的显示容器，网格显示对象，还可以是自定义的其他显示对象。
     * @see dragonBones.Armature
     * @see dragonBones.Bone
     * @see dragonBones.objects.SlotData
	 * @version DragonBones 3.0
	 */
	public class Slot extends TransformObject
	{
		/**
		 * @language zh_CN
		 * 显示的子骨架是否继承主骨架的动画。 (默认: <code>true</code>，仅在显示对象中包含子骨架时才有效)
		 * @version DragonBones 4.5
		 */
		public var inheritAnimation:Boolean;
		
		/**
		 * @language zh_CN
		 * 显示对象所受到控制对象，应设置为 AnimationState 的 name 或 group。 (默认: <code>null</code> 受所有的动画状态控制)
		 * @see dragonBones.animation.AnimationState#displayControl
		 * @see dragonBones.animation.AnimationState#name
		 * @see dragonBones.animation.AnimationState#group
		 * @version DragonBones 4.5
		 */
		public var displayController:String;
		
		/**
		 * @private SlotTimelineState
		 */
		dragonBones_internal var _colorDirty:Boolean;
		
		/**
		 * @private FFDTimelineState
		 */
		dragonBones_internal var _ffdDirty:Boolean;
		
		/**
		 * @private
		 */
		dragonBones_internal var _blendIndex:int;
		
		/**
		 * @private
		 */
		dragonBones_internal var _zOrder:int;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _displayDataSet:SlotDisplayDataSet;
		
		/**
		 * @private
		 */
		dragonBones_internal var _meshData:MeshData;
		
		/**
		 * @private BoneTimelineState
		 */
		dragonBones_internal var _cacheFrames:Vector.<Matrix>;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _rawDisplay:Object;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _meshDisplay:Object;
		
		/**
		 * @private SlotTimelineState
		 */
		dragonBones_internal const _colorTransform:ColorTransform = new ColorTransform();
		
		/**
		 * @private FFDTimelineState
		 */
		dragonBones_internal const _ffdVertices:Vector.<Number> = new Vector.<Number>(0, true);
		
		/**
		 * @private Factory
		 */
		dragonBones_internal const _replaceDisplayDataSet:Vector.<DisplayData> = new Vector.<DisplayData>(0, true);
		
		/**
		 * @private
		 */
		protected var _displayDirty:Boolean;
		
		/**
		 * @private
		 */
		protected var _blendModeDirty:Boolean;
		
		/**
		 * @private
		 */
		protected var _originDirty:Boolean;
		
		/**
		 * @private
		 */
		protected var _transformDirty:Boolean;
		
		/**
		 * @private
		 */
		protected var _displayIndex:int;
		
		/**
		 * @private
		 */
		protected var _blendMode:int;
		
		/**
		 * @private
		 */
		protected var _display:Object;
		
		/**
		 * @private
		 */
		protected var _childArmature:Armature;
		
		/**
		 * @private
		 */
		protected const _localMatrix:Matrix = new Matrix();
		
		/**
		 * @private
		 */
		protected const _displayList:Vector.<Object> = new Vector.<Object>(0, true);
		
		/**
		 * @private
		 */
		protected const _meshBones:Vector.<Bone> = new Vector.<Bone>(0, true);
		
		/**
		 * @private
		 */
		public function Slot(self:Slot)
		{
			super(self);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			const disposeDisplayList:Vector.<Object> = new Vector.<Object>();
			for each (var eachDisplay:Object in this._displayList)
			{
				if (disposeDisplayList.indexOf(eachDisplay) < 0)
				{
					disposeDisplayList.push(eachDisplay);
				}
			}
			
			for each (eachDisplay in disposeDisplayList)
			{
				if (eachDisplay is Armature)
				{
					(eachDisplay as Armature).returnToPool();
				}
				else
				{
					this._disposeDisplay(eachDisplay);
				}
			}
			
			inheritAnimation = true;
			displayController = null;
			
			_colorDirty = false;
			_ffdDirty = false;
			_blendIndex = 0;
			_zOrder = 0;
			_displayDataSet = null;
			_meshData = null;
			_cacheFrames = null;
			_rawDisplay = null;
			_meshDisplay = null;
			//_colorTransform;
			
			if (_ffdVertices.length)
			{
				_ffdVertices.fixed = false;
				_ffdVertices.length = 0;
				_ffdVertices.fixed = true;
			}
			
			if (_replaceDisplayDataSet.length)
			{
				_replaceDisplayDataSet.fixed = false;
				_replaceDisplayDataSet.length = 0;
				_replaceDisplayDataSet.fixed = true;
			}
			
			_displayDirty = false;
			_blendModeDirty = false;
			_originDirty = false;
			_transformDirty = false;
			_displayIndex = 0;
			_blendMode = DragonBones.BLEND_MODE_NORMAL;
			_display = null;
			_childArmature = null;
			_localMatrix.identity();
			
			if (_displayList.length)
			{
				_displayList.fixed = false;
				_displayList.length = 0;
				_displayList.fixed = true;
			}
			
			if (_meshBones.length)
			{
				_meshBones.fixed = false;
				_meshBones.length = 0;
				_meshBones.fixed = true;
			}
		}
		
		// Abstract method
		
		/**
		 * @private
		 */
		protected function _onUpdateDisplay():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _initDisplay(value:Object):void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _addDisplay():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _replaceDisplay(value:Object):void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _removeDisplay():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _disposeDisplay(value:Object):void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _getDisplayZIndex():int
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _setDisplayZIndex(value:int):void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private Bone
		 */
		dragonBones_internal function _updateVisible():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _updateBlendMode():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _updateColor():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _updateFilters():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _updateFrame():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _updateMesh():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _updateTransform():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		[inline]
		final private function _isMeshBonesUpdate():Boolean
		{
			for (var i:uint = 0, l:uint = _meshBones.length; i < l; ++i)
			{
				if (_meshBones[i]._transformDirty)
				{
					return true;
				}
			}
			
			return false;
		}
		
		/**
		 * @private
		 */
		protected function _updateDisplay():void
		{	
			const prevDisplay:Object = _display || _rawDisplay;
			const prevChildArmature:Armature = _childArmature;
			
			if (_displayIndex >= 0 && _displayIndex < _displayList.length)
			{
				_display = _displayList[_displayIndex];
				if (_display is Armature)
				{
					_childArmature = _display as Armature;
					_display = _childArmature.display;
				}
				else
				{
					_childArmature = null;
				}
			}
			else
			{
				_display = null;
				_childArmature = null;
			}
			
			const currentDisplay:Object = _display || _rawDisplay;
		
			if (currentDisplay != prevDisplay)
			{
				_onUpdateDisplay();
				
				if (prevDisplay)
				{
					_replaceDisplay(prevDisplay);
				}
				else
				{
					_addDisplay();
				}
				
				_blendModeDirty = true;
				_colorDirty = true;
			}
			
			// update origin
			if (_displayDataSet && _displayIndex >= 0 && _displayIndex < _displayDataSet.displays.length)
			{
				this.origin.copyFrom(_displayDataSet.displays[_displayIndex].transform);
				_originDirty = true;
			}
			
			// update meshData
			_updateMeshData(false);
			
			if (currentDisplay == _rawDisplay || currentDisplay == _meshDisplay)
			{
				_updateFrame();
			}
			
			// update child armature
			if (_childArmature != prevChildArmature)
			{
				if (prevChildArmature)
				{
					prevChildArmature._parent = null; // Update child armature parent
					if (inheritAnimation)
					{
						prevChildArmature.animation.reset();
					}
				}
				
				if (_childArmature)
				{
					_childArmature._parent = this; // Update child armature parent
					if (inheritAnimation)
					{
						_childArmature.animation.play();
					}
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function _updateLocalTransformMatrix():void
		{
			this.global.copyFrom(this.origin).add(this.offset).toMatrix(_localMatrix);
		}
		
		/**
		 * @private
		 */
		protected function _updateGlobalTransformMatrix():void
		{
			this.globalTransformMatrix.copyFrom(_localMatrix);
			this.globalTransformMatrix.concat(this._parent.globalTransformMatrix);
			this.global.fromMatrix(this.globalTransformMatrix);
		}
		
		/**
		 * @inheritDoc
		 */
		override dragonBones_internal function _setArmature(value:Armature):void
		{
			if (this._armature == value)
			{
				return;
			}
			
			if (this._armature)
			{
				this._armature._removeSlotFromSlotList(this);
			}
			
			this._armature = value;
			
			_onUpdateDisplay(); // Update renderDisplay
			
			if (this._armature)
			{
				this._armature._addSlotToSlotList(this);
				_addDisplay();
			}
			else
			{
				_removeDisplay();
			}
		}
		
		/**
		 * @private Armature
		 */
		dragonBones_internal function _updateMeshData(isTimelineUpdate:Boolean):void
		{
			const prevMeshData:MeshData = _meshData;
			
			if (_display == _meshDisplay && _displayDataSet && _displayIndex >= 0 && _displayIndex < _displayDataSet.displays.length)
			{
				_meshData = _displayDataSet.displays[_displayIndex].meshData;
			}
			else
			{
				_meshData = null;
			}
			
			if (_meshData != prevMeshData)
			{
				if (_meshData)
				{
					var i:uint = 0, l:uint = 0;
					
					_meshBones.fixed = false;
					_ffdVertices.fixed = false;
					
					if (_meshData.skinned)
					{
						_meshBones.length = _meshData.bones.length;
						
						for (i = 0, l = _meshBones.length; i < l; ++i)
						{
							_meshBones[i] = this._armature.getBone(_meshData.bones[i].name);
						}
						
						var ffdVerticesCount:uint = 0;
						for (i = 0, l = _meshData.boneIndices.length; i < l; ++i)
						{
							ffdVerticesCount += _meshData.boneIndices[i].length;
						}
						
						_ffdVertices.length = ffdVerticesCount * 2;
					}
					else
					{
						_meshBones.length = 0;
						_ffdVertices.length = _meshData.vertices.length;
					}
					
					_meshBones.fixed = true;
					_ffdVertices.fixed = true;
					_ffdDirty = true;
				}
				else
				{
					_meshBones.fixed = false;
					_meshBones.length = 0;
					_meshBones.fixed = true;
					
					_ffdVertices.fixed = false;
					_ffdVertices.length = 0;
					_ffdVertices.fixed = true;
				}
				
				if (isTimelineUpdate)
				{
					_armature.animation._updateFFDTimelineStates();
				}
			}
		}
		
		/**
		 * @private Armature
		 */
		dragonBones_internal function _update(cacheFrameIndex:int):void
		{
			_blendIndex = 0;
			
			if (_displayDirty)
			{
				_displayDirty = false;
				_updateDisplay();
			}
			
			if (!_display)
			{
				return;
			}
			
			if (_blendModeDirty)
			{
				_blendModeDirty = false;
				_updateBlendMode();
			}
			
			if (_colorDirty)
			{
				_colorDirty = false;
				_updateColor();
			}
			
			if (_meshData)
			{
				if (_ffdDirty || (_meshData.skinned && _isMeshBonesUpdate()))
				{
					_ffdDirty = false;
			
					_updateMesh();
				}
				
				if (_meshData.skinned)
				{
					return;
				}
			}
			
			if (_originDirty)
			{
				_originDirty = false;
				_transformDirty = true;
				_updateLocalTransformMatrix();
			}
			
			if (cacheFrameIndex >= 0 && _cacheFrames)
			{
				const cacheFrame:Matrix = _cacheFrames[cacheFrameIndex];
				
				if (this.globalTransformMatrix == cacheFrame) // Same cache
				{
					_transformDirty = false;
				}
				else if (cacheFrame) // has been Cached
				{
					_transformDirty = true;
					this.globalTransformMatrix = cacheFrame;
				}
				else if (_transformDirty || this._parent._transformDirty)
				{
					_transformDirty = true;
					this.globalTransformMatrix = this._globalTransformMatrix;
				}
				else if (this.globalTransformMatrix != this._globalTransformMatrix) // Same cache but not cached yet
				{
					_transformDirty = false;
					_cacheFrames[cacheFrameIndex] = this.globalTransformMatrix;
				}
				else
				{
					_transformDirty = true;
					this.globalTransformMatrix = this._globalTransformMatrix;
				}
			}
			else if (_transformDirty || this._parent._transformDirty)
			{
				_transformDirty = true;
				this.globalTransformMatrix = this._globalTransformMatrix;
			}
			
			if (_transformDirty)
			{
				_transformDirty = false;
				
				if (this.globalTransformMatrix == this._globalTransformMatrix)
				{
					_updateGlobalTransformMatrix();
					
					if (cacheFrameIndex >= 0 && _cacheFrames)
					{
						this.globalTransformMatrix = SlotTimelineData.cacheFrame(_cacheFrames, cacheFrameIndex, this._globalTransformMatrix);
					}
				}
				
				_updateTransform();
			}
		}
		
		/**
		 * @private Factory
		 */
		dragonBones_internal function _setDisplayList(value:Vector.<Object>):Boolean
		{
			if (value && value.length)
			{
				if (_displayList.length != value.length)
				{
					_displayList.fixed = false;
					_displayList.length = value.length;
					_displayList.fixed = true;
				}
				
				for (var i:uint = 0, l:uint = _displayList.length; i < l; ++i)
				{
					const eachDisplay:Object = value[i];
					if (eachDisplay && eachDisplay != _rawDisplay && !(eachDisplay is Armature) && _displayList.indexOf(eachDisplay) < 0)
					{
						_initDisplay(eachDisplay);
					}
					
					_displayList[i] = eachDisplay;
				}
			}
			else if (_displayList.length)
			{
				_displayList.fixed = false;
				_displayList.length = 0;
				_displayList.fixed = true;
			}
			
			if (_displayIndex >= 0 && _displayIndex < _displayList.length)
			{
				_displayDirty = _display != _displayList[_displayIndex];
			}
			else
			{
				_displayDirty = _display != null;
			}
			
			return _displayDirty;
		}
		
		/**
		 * @private Factory
		 */
		dragonBones_internal function _setDisplayIndex(value:int):Boolean
		{
			if (_displayIndex == value)
			{
				return false;
			}
			
			_displayIndex = value;
			_displayDirty = true;
			
			return _displayDirty;
		}
		
		/**
		 * @private Factory
		 */
		dragonBones_internal function _setBlendMode(value:int):Boolean
		{
			if (_blendMode == value)
			{
				return false;
			}
			
			_blendMode = value;
			_blendModeDirty = true;
			
			return true;
		}
		
		/**
		 * @private Factory
		 */
		dragonBones_internal function _setColor(value:ColorTransform):Boolean
		{
			_colorTransform.alphaMultiplier = value.alphaMultiplier;
			_colorTransform.redMultiplier = value.redMultiplier;
			_colorTransform.greenMultiplier = value.greenMultiplier;
			_colorTransform.blueMultiplier = value.blueMultiplier;
			_colorTransform.alphaOffset = value.alphaOffset;
			_colorTransform.redOffset = value.redOffset;
			_colorTransform.greenOffset = value.greenOffset;
			_colorTransform.blueOffset = value.blueOffset;
			
			_colorDirty = true;
			
			return true;
		}
		
		/**
		 * @language zh_CN
		 * 
		 * @version DragonBones 4.5
		 */
		public function invalidUpdate():void
		{
			_displayDirty = true;
		}
		
		/**
		 * @private
		 */
		public function get rawDisplay():Object
		{
			return _rawDisplay;
		}
		
		/**
		 * @private
		 */
		public function get MeshDisplay():Object
		{
			return _meshDisplay;
		}
		
		/**
		 * @language zh_CN
		 * 此时显示的显示对象在显示列表中的索引。
		 * @version DragonBones 4.5
		 */
		public function get displayIndex():int
		{
			return _displayIndex;
		}
		public function set displayIndex(value:int):void
		{
			if (_setDisplayIndex(value))
			{
				_update(-1);
			}
		}
		
		/**
		 * @language zh_CN
		 * 包含显示对象或子骨架的显示列表。
		 * @version DragonBones 3.0
		 */
		public function get displayList():Vector.<Object>
		{
			return _displayList.concat();
		}
		public function set displayList(value:Vector.<Object>):void
		{
			const backupDisplayList:Vector.<Object> = _displayList.concat();
			const disposeDisplayList:Vector.<Object> = new Vector.<Object>();
			
			if (_setDisplayList(value))
			{
				_update(-1);
			}
			
			for each (var eachDisplay:Object in backupDisplayList)
			{
				if (eachDisplay != _rawDisplay && _displayList.indexOf(eachDisplay) < 0)
				{
					if (disposeDisplayList.indexOf(eachDisplay) < 0)
					{
						disposeDisplayList.push(eachDisplay);
					}
				}
			}
			
			for each (eachDisplay in disposeDisplayList)
			{
				if (eachDisplay is Armature)
				{
					(eachDisplay as Armature).returnToPool();
				}
				else
				{
					_disposeDisplay(eachDisplay);
				}
			}
		}
		
		/**
		 * @language zh_CN
		 * 此时显示的显示对象。
		 * @version DragonBones 3.0
		 */
		public function get display():Object
		{
			return _display;
		}
		public function set display(value:Object):void
		{
			if (_display == value)
			{
				return;
			}
			
			const displayListLength:uint = _displayList.length;
			if (_displayIndex < 0 && displayListLength == 0)  // Emprty
			{
				_displayIndex = 0;
			}
			
			if (_displayIndex < 0)
			{
				return;
			}
			else
			{
				const replaceDisplayList:Vector.<Object> = displayList; // copy
				if (displayListLength <= _displayIndex)
				{
					replaceDisplayList.fixed = false;
					replaceDisplayList.length = _displayIndex + 1;
					replaceDisplayList.fixed = true;
				}
				
				replaceDisplayList[_displayIndex] = value;
				displayList = replaceDisplayList;
			}
		}
		
		/**
		 * @language zh_CN
		 * 此时显示的子骨架。
		 * @see dragonBones.Armature
		 * @version DragonBones 3.0
		 */
		public function get childArmature():Armature
		{
			return _childArmature;
		}
		public function set childArmature(value:Armature):void
		{
			if (_childArmature == value)
			{
				return;
			}
			
			display = value;
		}
	}
}