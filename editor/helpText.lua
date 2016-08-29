return [[
欢迎来到Alexar's box2d编辑器(ABE)的帮助文档！
	ABE是一个基于box2d的物理场景编辑器。使用它，可以轻松且可视的创建和编辑box2d的场景，目前仅支持以luatable格式导出。结合本编辑器的运行时，可以很方便的将物理场景置入你的游戏中。当然本编辑器本身也可以作为一个游戏来玩，未来将导入一些游戏事件，使你的游戏更加完整。
	本帮助文档将帮助你了解并熟练使用这个编辑器，期间也将讲解一些box2d的知识，不过即使你不了解box2d使用这个工具也很容易。与本帮助文档对应的，还有一套教程。本帮助主要以介绍和解释入手，而教程则从实践出发，通过学习，你一定会做出一些有意思的创造。
	好了！让我们开始探索box2d的奇妙世界吧！

第一章 Box2d的基本概念
	本章将介绍box2d的一些基本概念，便于你对之后操作的理解。如果你对box2d已经有一些经验的话，可以跳过本章。
	第一节 什么是box2d
		box2d是一个开源的C++物理引擎，用来模拟物理效果和行为的。比较出名的愤怒的小鸟，割绳子，粘粘世界等游戏都用了这个物理引擎。当然还有比较直接的应用，比如物理蜡笔等等。
		box2d有别一般碰撞检测库在于它不但能够侦测物体碰撞，而且能够仿真的模拟物体碰撞结果，以及各种受力情况。因此使用了物理引擎的游戏在碰撞表现上更加真实。                              
	第二节 box2d的主要对象
		我们使用box2d，实际上就是跟box2d的各种对象打交道，它主要的对象有以下几种，世界，刚体，形状，部件，连接，碰撞。我们通过创建这些对象，赋予他们属性，使用他们的方法来实现物理模拟。
	第三节 世界
		世界是box2d的舞台，创建任何物体都要指定一个舞台。而舞台有其本身的物体属性。
		1. 比例尺 作用跟地图的比例尺差不多，告诉物理引擎屏幕的多长相当于1米，本引擎默认的是64像素-1米，意味着如果你的电脑显示器的分辨率为1280*760，那么相当于物理世界的大概220平方米左右。
		2. 重力   物理世界的重力，分为x轴和y轴（正向为右下）。一般如果模拟俯视视角，重力为0,0.如果模拟切面，比如卷轴游戏，那么重力为0,9.8*比例尺。注意比例尺的存在，需要调整合适的屏幕缩放才能看到比较真实的仿真。
		3. 允许休眠 如果允许休眠，那么静止的物体将休眠除非再次激活（如碰撞）。允许休眠可以提高效率。
		4. 全局线性速度衰减 这个属性是编辑器赋予的，为了模仿全局的摩擦力。让线性运动（改变x,y的运动）的物体停下来。
		5. 全局角速度衰减 这个属性是编辑器赋予的，为了模仿全局的摩擦力。让转动（改变角度的运动）的物体停下来。		
	第四节 刚体
		刚体是box2d物理模拟的核心。它的功能主要体现在受力模拟上。刚体之所以叫刚体，是有别于柔体，流体等，意味着碰撞不会发生形变。所以box2d主要模拟的是刚体碰撞。当然还有一些其他的技巧可以让你模拟柔体、流体等。
		从物理角度讲，与其叫做刚体，不如叫做质点。在处理物体受力上，一般的都以它为中心。刚体的属性主要也跟力学有关。
		1. x,y,angle 这三个属性决定了物体的位置和角度，注意的是，游戏的精灵与附着其上的刚体位置角度同步容易出现问题。这里不做详细解释。
		2. 角速度，线速度  这个属性决定了物体的运动状态，也就是每秒移动、转动多少。
		3. 线性速度衰减和角速度衰减 这个属性的初始值由世界设定。有了他们物体就会停下来。
		4. 重力缩放 这个属性可以影响重力对物体的受力，比如y向为负，可以模拟气球的浮力。
		5. 子弹 这个属性可以让物体碰撞计算变为连续计算，从而避免物体运动速度过高而跳过某些物体的碰撞（因为电脑模拟是有帧率的，中间会出现间隔，也就是物体是跳跃式的移动的）
		6. 类型 刚体有动态，静态，运动三种类型，动态的物体受力会移动，静态的物体受力不会移动，运动类型的物体只跟动态的物体发生碰撞但不会对受力有反应。
		刚体还有其他一些属性，我们暂时不去过深的了解了。
	第五节 形状
		形状可以说不算是一个独立的对象，它必须与部件联合使用才有意义。
		1. 线、折线 他们主要用作地形边缘。因为他们是线，没有体积，只能跟有体积的物体产生碰撞。
		2. 圆形 我们知道在电脑绘制圆只不过是正n边形。不过圆形意义在于物理模拟上，比如滚动。
		3. 矩形，多边形 矩形也是多边形，box2d中的多边形要求不能为凹多边形，同时定点数不能超过8个。如果想要更复杂的多边形就需要由多个三角形来拼接。
	第六节 部件
		部件是除了刚体外，又一个重要对象。不同于刚体用于受力，部件主要用于碰撞以及决定物体的材质。当然由于体积的存在，使得物体具有质量。一个box2d物理世界的物体，必须由刚体和部件共同构成。一个物体只能拥有一个刚体，但可以拥有多个部件。比如一个桌子由桌面和四条腿五个部件组成。
		部件的定义必须有一个形状。部件的属性决定了部件的材质和作用。
		1. 密度 决定了物体的单位面积的质量。因为是2d模拟，因此只有单位面积了。
		2. 摩擦系数 摩擦系数决定物体之间是否容易滑动。
		3. 弹力系数 弹力决定了物体碰撞到另一个物体之后能否反弹。反弹的结果是根据碰撞的物体双方弹力决定的
		4. 感受器 当部件成为感受器后，虽然可以产生碰撞，但不会发生碰撞模拟。比如红外门禁。
		5. 碰撞组 碰撞组决定了这个部件会与那些分组产生碰撞，而哪些不碰撞。
	第七节 连接
		连接或者称关节，是box2d处理物体间相互联动的一种方式。类似于我们常见的一些简单的物理机械。有了他们，我们可以很方便的创建机械而不必手动打造每个部件（即使可以，那样也不够精确，而且模拟并非真实）。
		一般来讲连接是针对刚体之间的。因为他们是受力的载体。从本质来讲，连接的作用是将两个物体的运动状态做关联或限制。
		1. 绳索连接
			绳索连接可以限制让两个物体像连在绳子上一样，距离小于绳子不限制，而距离大于绳子将受到束缚，而且转动不限制，比如吊灯。还有一个功能是设置束缚频率，这样可以模仿拉簧的行为。
		2. 距离连接
			距离连接可以限制两个物体的距离，也就是限制相对移动，但不限制相对旋转。同样可以设置束缚频率，可以用来模拟弹簧。
		3. 焊接连接
			焊接连接将同时限制相对移动和相对旋转，就像焊接一样。不过要注意由于box2d算法顺序的问题，焊接连接并不是完全禁止相对移动（可以想象计算频率为最大，每帧都计算），同样有束缚频率，可以用来模拟扭簧。			
		4. 转动连接
			转动连接也叫轴连接，意味着它限制相对位移，但不限制旋转，所以物体可以像被轴连在一起一样。转动连接有个特殊属性是转动马达，可以为物体间相互转动提供动力。同时转动还可以限制角度。
		5. 平移连接
			平移连接也叫活塞连接，它将限制除了给定轴的其他相对移动及转动。因此它可以像活塞一样相对平行移动。平移可以有限制最大距离和最小距离。跟转动连接一样，可以为其相对移动提供内在动力。
		6. 滑轮连接
			滑轮连接顾名思义类似于定滑轮，可以改变物体的相对受力方向。同时也可以设置比率来模拟滑轮组。
		7. 悬轮连接
			悬架轮连接，是类似于车的悬架和轮子的组合，它允许两个物体在一个轴相对移动，但不限制物体的自转。这里就可以解决如使用转动连接制作的小车在颠簸路段会卡住的问题。
		8. 传动连接
			传动连接是一种特殊的连接，他的对象是转动连接或者平移连接，它能够将相对移动或转动按一定比例转化为同一种或另一种。类似于曲轴传动或者齿轮传动。
	第八节 碰撞
		碰撞的控制由世界的碰撞回调函数控制的，在碰撞回调中会传入一个碰撞对象来控制碰撞行为。
		1. 碰撞组 
			box2d的碰撞过滤是通过关节处理、分组、分类、全局过滤四种情形处理的。分别在关节属性，组索引，类和掩码，全局碰撞过滤几处定义。详细见附录。
		2. 碰撞的几个回调
			他们都是在世界定义中，使用setcallbacks来定义的，下面将按照实际处理的顺序来介绍这几个回调。实际设置顺序与之不同。
			a. 处理前回调，发生在系统检测到下一次移动即可导致碰撞时回调，此时物体还没因为碰撞而导致速度及受力变化。因此如果你不想他们碰撞，或者希望碰撞不以普通的物理表现而进行时，要在这里添加代码。
			b. 处理后回调，这里是碰撞处理后时的回调，也就是发生了速度改变后的状态，如果你希望附加一些受力，或者切换一些在处理前回调中导致的异常状态时，可以在这里编辑回调。
			c. 开始回调，这发生在两个物体有交叠（碰撞）时，当有交叠则此回调每一帧都要返回。
			d. 结束回调，这发生在两个物体不再有交叠（碰撞）时，一次碰撞只发生一次。
		3. 碰撞对象
			碰撞对象是碰撞回调中返回的一个参数，通过碰撞对象，我们可以控制碰撞是否发生，得到物体碰撞的位置，角度，线性冲量及角冲量等等。
第二章 熟悉box2d编辑器界面
	要想熟练使用ABE编辑器，首先要了解它的界面，知道它的功能及位置。ABE的操作界面分为3个区域，菜单导航区，可移动工具栏及box2d编辑界面。
	第一节 主菜导航
		菜单导航中罗列了ABE编辑器的主要功能，分为系统栏、编辑栏、模式栏、布局栏、视觉栏及捐助按钮。
		1. 系统栏 主要包含项目新增及存储，场景新增及存储，快捷键绑定，帮助，教程等内容。
			a. 新建项目 当你第一次进入编辑器时，会要求新建项目，以便存储编辑器信息。新建时需要键入文件名，请不要输入中文及不符合当前系统路径命名规则的项目名。
			b. 保存项目 保存当前项目下的所有信息，包括：当前项目，当前场景，项目建立时间，最后编辑时间，当前窗体大小及界面布置，按键绑定等信息。项目存储于“C:\Users\username\AppData\Roaming\LOVE\ABE\projectname”目录下,可以按ctrl+home键打开存储文件夹。
			c. 读取项目 系统将弹出项目读取窗体，在窗体中单击项目名称读取项目，并将其切换到当前项目。在读取项目窗体中可以按住ctrl+alt单击某项目来删除项目，被删除的项目无法恢复，注意！
			d. 项目另存 可以将当前项目以另一个名称存储一个副本。
			e. 新建场景 新建场景并不会要求你马上保存，而新建的场景的名称为default。如果不手动保存场景，改场景将被放弃。
			f. 保存场景 每一个场景就是一个box2d世界，里面包含着一个物理世界的所有信息。
			g. 场景另存 可以将当前场景以另一个名称存储一个副本。
			h. 按键配置 将弹出一个按键配置窗口，里面包含本编辑器的所有快捷键，可以点击某个按键功能，键入任意未被占用的键来替换快捷键。目前仅支持左ctrl及左alt键作为组合键。请认真的设置快捷键，因为本编辑器使用快捷键的编辑效率比不使用高很多。
			i. 帮助 就是本文档了，是对box2d的基本原理及ABE编辑器操作方法的介绍。
			j. 教程 从实践入手，由浅入深的教你是用ABE编辑器来编辑你想象中的那个物理世界。
			k. 关于 有关版本号及版权信息、用户授权信息的内容。
		2. 编辑栏 主要提供对世界编辑相关的有用功能。
			a. 撤销 取消上一次编辑动作
			b. 重做 重做上一次编辑动作
			c. 复制 复制已经选中的单个或多个物体
			d. 粘贴 将已复制的物体粘贴到世界中
			e. 单元创建 将选中的单个或多个物体存入单元框中，以便随时复用。这个是对复制粘贴功能的拓展，后面将详细叙述。
			f. 全选 选中整个世界中的所有物体
			g. 空选 取消选择
			h. 反选 选中整个世界中除了已选中的物体。
			i. 清空场景 清空整个世界
			j. 移除刚体 移除一个已选中的刚体，如果刚体包含连接，也同时移除连接。
			k. 移除连接 移除已选中的两个物体间的连接。选中的物体必须是有连接的两个物体。
			l. 合并刚体 将多个刚体合并为一个刚体，以选中的第一个刚体为合并后的刚体，其他刚体的部件设为合并后刚体的部件。
			m. 切分刚体 将一个包含多个部件的刚体切分为多个独立刚体，每个部件将分配一个刚体。
			n. 切换刚体类型 切换刚体类型，包括静态，动态和运动三个类型。
			o. 水平对齐 将选中的所有刚体向选中的第一个刚体做水平对齐。
			p. 垂直对齐 将选中的所有刚体向选中的第一个刚体做垂直对齐。
		3. 模式栏 本栏提供各种编辑模式间的切换，当前的编辑模式将在屏幕中间靠上方显示。
			a. 刚体模式
				刚体模式是编辑模式中的主要模式，他负责物体的创建，位置的摆放，刚体的属性，用户信息及世界属性的设置等。
			b. 部件模式
				部件模式可以编辑物体的部件，可以设置部件的属性以及改变部件的位置等。
			c. 形状模式
				形状模式可以增加/删除/移动已有的多边形的顶点来改变形状。
			d. 连接模式
				连接模式主要用来更改连接的锚点位置，删除链接，增加联动连接等操作。
			模式切换的快捷键是1,2,3,4。请记住，因为你会经常用到他们的。
			具体的操作将在后面详细介绍。
		4. 布局栏。
			它的作用是切换编辑器窗体中各种可移动的工具栏及日志和网格标尺的显示状态。布局状态将存储在项目文件中，下次进入编辑器时，将还原布局状态。
		5. 视觉/可见栏。
			它的作用主要是针对物理世界的。它可以切换物体的刚体，部件，连接，碰撞点，纹理等的可见性，也可以调整他们的颜色。
			另外，本栏还提供了两个比较好玩的全屏特效，一个是全屏泛光，实际是一个模糊滤镜，另一个是尾迹绘制，可以比较直观的看到物体的动态效果。不过看多了也有点眩晕的感觉。:)
		6. 捐助
			抱歉把这个无聊的功能加入到了主菜单。本软件的生存和发展需要各位的帮助，任何帮助都是对作者极大的肯定。当然本软件免费使用。
	第二节 创建栏
		创建栏是APE的重要组成部分，用于创建物体，点击这个按钮然后再屏幕按要求操作即可。当然如果使用快捷键大大加快你的编辑速度。另外如果按住lshift键，可以创建软性物体！一种很神奇的刚体组合，试试就知道了。对于创建刚体的具体操作，我们将在后面详细讲解。
	第三节 属性栏
		属性窗体任何模式单击相应对象即可弹出，当然可以用布局来让其不可见。在刚体模式，可以弹出刚体的相应属性，在形状模式可以弹出形状的属性等等。刚体属性有一栏可以设置世界属性。（我不太想单独把世界属性拿出来，因此放到了刚体里）
	第四节 单位栏及预览
		单位栏是为了方便复用曾经做过的部件或物体，比如我们制作一个小车即可选中他们，存入单位栏，我们把鼠标移至改单位时，会显示一个小型的预览，点击后，该单位就被存储到了剪贴板中。用ctrl+v或者粘贴按钮即可加入到场景中。同样按住ctrl+alt点击物体即可删除这个单位。单位在项目中的所有场景共享。是ctrl+c和ctrl+v的拓展功能。
	第五节 历史栏
		历史栏中展现了曾经发生的15次（以后可以自己设置）操作，当我们点击之前的历史时即可还原到那一步操作。是ctrl+z和ctrl+y的拓展功能。
	第六节 标尺网格、操作日志
		标尺网格可以让我们比较容易的对其各种对象，以及在创建时让用户清楚物体的大小，每一个相当于现实的1平方米。（以后可以设置标尺网格的密度）
		操作日志主要是为了方便系统想用户提示各种信息，比如错误的用户操作等。（目前功能比较局限，以后拓展）
	第七节 编辑界面
		编辑界面就是我们的主界面，在这个界面中可以编辑box2d的世界，当前的项目及场景名称显示在上部。当前场景的基本信息显示在下部。
		以下是编辑界面的基本操作，一些功能是固定的，因此未出现在按键绑定中。
		镜头缩放 鼠标滚轮前后移动
		镜头移动 按住空格键拖动鼠标
		镜头跟随 在进入测试模式前，选中某个物体，在测试模式时，镜头将跟随这个物体。
		单选 鼠标单击
		添选 按住ctrl单击是添加选择，每次单击都会将被选单位添加到选区
		框选 鼠标拖动
		取消 escape键，这个键可以取消选择或创建状态（详见创建章节）。
		选择切换 当一个单击位置有数个物体时，可以按右键来切换选择的物体。
第三章 创建刚体及编辑
	本章将介绍创建各种刚体及高级创建。对刚体的编辑等知识。
	第一节 刚体的创建
		1. 圆形
		点击创建栏的圆形或快捷键c(circle)，进入圆形创建，点击确定圆心后拖动鼠标，释放后即可创建圆。
		2. 方形
		点击创建栏的方形或快捷键b(box),进入方形创建，点击确定方形的左上角位置，拖动鼠标，释放后即可创建方形。
		3. 多边形
		点击创建栏的多边形或快捷键p(polygon),进入多边形创建，点击确定多边形的第一个顶点，按住，每加入一个顶点点击鼠标右键一次，释放后即可创建。
		4. 直线
		点击创建栏的直线或快捷键l(line),进入直线创建，点击后拖动鼠标，释放时即可创建直线。
		5. 折线
		点击创建栏的折线或快捷键z(zigzag),进入折线创建，点击确定多边形的第一个顶点，按住，每加入一个顶点点击鼠标右键一次，释放后即可创建。
		6. 曲线/自由画笔
		点击创建栏的曲线或快捷键f(freedraw),进入曲线创建，点击后自由绘制，鼠标释放时即可创建。如果需要曲线比较平滑，请缓慢移动鼠标。
	第二节 高级创建
		1. 软体圆
		方法同创建圆，按住shift时点击创建圆或shift+c。
		2. 软体方形
		方法同创建方形，按住shift时点击创建方形或shift+b。
		3. 软体多边形
		方法同创建多边形，按住shift时点击创建多边形或shift+p。
		4. 软绳
		方法同创建直线，按住shift时点击创建直线或shift+l。
		5. 水粒子
		按住shift时点击折线按钮或按键e，进入创建, 按住即可加入，释放停止加入。注意加入太多的话会严重影响运行的。目前尚未控制加入数量。
		6. 爆炸物
		按住shift时点击曲线按钮或按键q，进入创建，创建方式如创建圆形。半径越大，爆炸威力越大。
	第三节 刚体的属性编辑
		选中任意刚体即可弹出属性编辑栏，第一个选项卡为属性，第二个为用户数据，第三个为世界属性
		1. 基本属性
		基本属性的概念在上文已经讲过，这里不再赘述。点击编辑框键入相应内容进行编辑，必须回车才可以生效，这里注意。暂时未加入错误数据的识别，注意！
		2. 用户数据
		注意！由于本编辑器大多数特殊功能均由userdata的特性关键词来触发，因此，在自定义用户数据时，为了避免用户数据冲突，请第一个字母大写。
		3. 反映触发
		在本编辑器中，内置了一些很有意思的触发功能，也就是绑定了一些基本的人机互动。在基本属性的action栏点击后可以看到可触发列表，点击后即可应用。具体请见触发相关章节。
		4. 世界属性
		世界属性不再赘述，编辑方式同其他属性编辑。
	第四节 刚体的编辑
		刚体的编辑主要是编辑物体的位置摆放。注意，物体的旋转被放在了形状模式了，可能有些不便，以后会把这个功能放到刚体编辑里面。
		对于很多操作是需要选中顺序的，框选是无顺序选择，而按住ctrl点选来确定其顺序。
		1. 移动及对齐
		选中一个或多个物体，拖动物体即可移动。可以使用h,v来对其第一个物体。
		2. 复制及粘贴
		可以对选中的一个或多个物体进行复制，ctrl+c,在目标地点ctrl+v来粘贴。也可以用对已选中的物体，按住ctrl拖动，释放来复制物体。注意！这个操作很容易跟复选操作冲突，即当按住ctrl点击未选中的物体时是复选，如果点击已选中的物体，有可能由于鼠标的细微移动导致物体被复制。
		3. 合并及拆分
		由于刚体模式中加入的形体都具有独立的刚体，有时为了创建具有多个部件的物体时，需要进行刚体合并，ctrl+b为快捷键。合并的刚体也可以按ctrl+d来拆分。
		4. 删除及清屏
		对于已创建的刚体，可以按delect键删除。按home键可以清空场景。
第四章 部件的编辑
	所有部件都是在刚体模式下生成的独立刚体中生成的。也可以通过刚体合并来得到。在部件编辑中，主要是对物体材质的编辑以及物体碰撞反馈的编辑.
	第一节 部件的基本属性
		选中任何部件，将弹出部件的属性窗体，对属性的意义和编辑方法前文已经讲解，这里不再赘述。
	第二节 部件的材质
		材质是对物体弹性，密度，摩擦等属性预设。你也可以直接编辑基本属性来调整。
	第三节 部件的用户数据
		同刚体的用户数据类似，请以大写字母开头来定义自定义属性。
	第四届 碰撞回馈
		与刚体的反映触发类似的，部件有碰撞回馈，这个功能是当物体有碰撞或碰撞倾向时被动触发的，里面预设了几种常用的碰撞回馈。我们后文将详细讲解。
第五节 形状的编辑
	形状编辑可以改变物体的形状，诸如圆的半径大小，多边形的顶点位置，物体旋转等功能。
	第一节 形状的属性
		在形状模式下，物体的顶点(圆将显示圆心和圆上一点)将显现出来，绿色点表示形状中心点，红色点表示顶点，选中任何顶点，将弹出形状的属性窗体，对属性的意义和编辑方法前文已经讲解，这里不再赘述。
	第二节 顶点的编辑
		对于圆，拖动圆上的点可以改变圆的半径。对于多边形，来讲拖动顶点可以改变多边形的形状，同样对于直线，折线，曲线也适用。
	第三节 自转和公转
		左键拖动中心点可以使物体沿中心点旋转，右键拖动中心点可以使物体沿坐标原点旋转。这里也有个快捷方式，就是按住ctrl拖动的话，每次释放都会创建一个副本。
第五章 连接的创建和编辑
	在连接模式中，连接的锚点将会被现实出来，点击任意锚点即可编辑连接的属性。
	第一节 连接的概念和种类
		连接的概念和种类已经在前文叙述了。
	第二节 绳索连接, 距离连接, 焊接连接
		由于这几种连接没有前后顺序，因此选中两个刚体后，点击相应的连接创建按钮或者快捷键r(rope),d(distance),w(weld)来创建连接。这里也有个连续创建的方法，就是用连选的方式选择多个刚体后，按连接，那么他们将首尾连接的。
		注意，他们都可以设置frequncy，处理频率来模拟弹力。
	第三节 转动连接, 平移连接
		这两种连接仅限于两个物体间连接，注意连接顺序，对于转动连接，其转动轴的锚点默认设置于第二个物体的刚体位置，因此如果做一个轮子的话，先选择车体，在选择轮子后按o来创建。
		对于平移连接，限制锚点处于第二个物体，方向从第一个物体指向第二个物体。当无限制时，默认值为0，100。快捷键为m
	第四节 滑轮连接
		滑轮连接需要两个物体。快捷键u(倒置的滑轮),另外滑轮连接可以设置滑轮比。
	第五节 悬轮连接
		悬轮连接类似于转动连接，需要注意选择顺序，记住，轮子永远后选就对了。快捷键i(倒置的轮轴)
	第六节 传动连接
		传动连接的创建需要在连接模式下，选中一个锚点（必须为转动连接或活塞连接）右键拖动至另一个锚点（同前），即可创建。点击锚点可以编辑属性。
	第七节 连接的锚点及编辑
		锚点的编辑只需拖动锚点即可改变位置，选中的锚点变为绿色，点击delete键即可删除其所在的连接，如果这个连接同时还连接一个传动连接，那么一并删除。
第六章 应用测试
	当你完成了一个场景的制作后，就可以进行测试了。测试之间如果你选定了某个物体，测试时镜头将跟随这个物体。（介绍一个快速移动镜头的方式，由于本编辑器没有设置小地图，所以在场景上快速移动镜头，只需要把镜头拉远，然后移动，然后再拉近，很方便的）
	测试的快捷键是f1,在测试过程中，再次按下f1将暂停。如果测试过程中按下任何模式切换键（1234）则结束测试模式，返回到测试之前的状态，切换到相应的编辑模式。在测试模式可以随时添加物体。
	测试过程中，有以下几种互动模式。
		a. 标准模式 在这个模式下，禁止一般的互动。
		b. 牵引模式 在这个模式下，要先选中你想要牵引的物体，然后拖动这个物体，物体跟你鼠标的距离越远，牵引力越大。
		c. 鼠标球模式 这个模式进入时会在鼠标的位置生成一个碰撞球，（这里使用的是特殊的鼠标连接，并未直接加入到编辑器中），碰撞球可以与场景中的物体互动。
		d. 按键模式 在这个模式下，要先选中一个物体，然后按住某些按键来施加力量。其中adsw为四个方向的作用力，而qe为顺时针和逆时针两个方向的扭力。
	测试完成后，回恢复到测试前的状态。
第七章 触发与回馈
	本编辑器的最大特色就是将一些常用的条件出发及碰撞回馈内置，直接一键添加效果。具体技术实现这里不加赘述，主要是利用了各种世界的碰撞回调完成的。
	触发一般是在帧回调中检测某种状态而进行某种动作。先下面介绍ABE的内置触发。
	1. 
第八章 单位及场景
	第一节 单位的创建
	第二节 存储、读取单位和场景
	第三节 场景拼接




















































Alexar
]]