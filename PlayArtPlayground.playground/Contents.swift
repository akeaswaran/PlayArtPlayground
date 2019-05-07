//: A UIKit based Playground for presenting user interface
  
import UIKit
import CoreFoundation

enum FCPlayRouteType : Int {
    case None
    // Offensive
    case Post
    case Screen
    case Streak
    case Flat
    case Comeback
    case Slant
    case Sweep
    case Dive
    case Wheel
    
    // defensive
    case Zone
    case Man
    case Blitz
}

enum FCPlayRunningDirection : Int {
    case Right
    case Left
    case SlantRight
    case SlantLeft
    case Straight
}

enum FCPlayAction : Int {
    // Offensive
    case Block
    case Rush
    case RunRoute
    case Pass
    case Handoff
    
    // defensive
    case Zone
    case Man
    case Blitz
}

enum FCPlayStartPosition : Int {
    // DL/OL
    case LOS
    
    // CB/WR
    case SlotRight
    case WideRight
    case TightRight
    case SlotLeft
    case WideLeft
    case TightLeft
    
    // Only QB
    case UnderCenter
    case Shotgun
    
    // RB/LB
    case BackfieldIFormMiddle
    case BackfieldPistolLeft
    case BackfieldPistolRight
    
    // RB only
    case BackfieldIFormDeep

    // S
    case DefensiveBackfieldDeepCenter
    case DefensiveBackfieldDeepLeft
    case DefensiveBackfieldDeepRight
}

/*
 to build a route action:
 {
     "action" : FCPlayActionRoute,
     "startPosition" : FCPlayStartPositionSlotLeft,
     "route" : {
         "type" : FCPlayRouteTypePost,
         "direction" : FCPlayRunningDirectionRight
     }
 }
 */

extension UIBezierPath {
    func addArrowhead(start: CGPoint, end: CGPoint, pointerLineLength: CGFloat, arrowAngle: CGFloat) {
        self.move(to: start)
        self.addLine(to: end)
        
        let startEndAngle = atan((end.y - start.y) / (end.x - start.x)) + ((end.x - start.x) < 0 ? CGFloat(Double.pi) : 0)
        let arrowLine1 = CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle + arrowAngle), y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle + arrowAngle))
        let arrowLine2 = CGPoint(x: end.x + pointerLineLength * cos(CGFloat(Double.pi) - startEndAngle - arrowAngle), y: end.y - pointerLineLength * sin(CGFloat(Double.pi) - startEndAngle - arrowAngle))
        
        self.addLine(to: arrowLine1)
        self.move(to: end)
        self.addLine(to: arrowLine2)
    }
}

class PlayArtView : UIView {
    
    let standardSize: CGFloat = 10
    let standardPadding: CGFloat = 2
    
    public var playActions: Dictionary<String, Array<Dictionary<String, Any>>> = [:]
    
    private func drawPlayerSet(actions: Array<Dictionary<String, Any>>) {
        if (actions.count == 0) {
            return;
        }
        for dict in actions {
            let pView: UIView = drawOffensivePlayer(inPosition: FCPlayStartPosition(rawValue: dict["startPosition"] as! Int) ?? .TightRight)
            let action: FCPlayAction = FCPlayAction(rawValue: dict["action"] as! Int) ?? .Block
            if (dict.keys.contains("route")) {
                let routeInfo = dict["route"] as? Dictionary<String, Any>
                //                print("ROUTEINFO:", routeInfo, "\n")
                if (routeInfo != nil) {
                    let type: FCPlayRouteType = FCPlayRouteType(rawValue: (routeInfo!["type"] as! Int)) ?? .Flat
                    //                    print("type optional unwrapped successfully")
                    let direction: FCPlayRunningDirection = FCPlayRunningDirection(rawValue: (routeInfo!["direction"] as! Int)) ?? .Right
                    //                    print("direction optional unwrapped successfully, heading to drawAction:")
                    drawAction(fromPosition: pView.center, action: action, routeType: type, direction: direction)
                }
            } else {
                drawAction(fromPosition: pView.center, action: action, routeType: nil, direction: nil)
            }
        }
    }
    
    private func drawOffensiveLine() {
        for i in 0...5 {
            let xView: UIView = drawOffensivePlayerRing(frame: CGRect(x: 0, y: 0, width: standardSize, height: standardSize), ringColor: UIColor.white)
            if (i % 2 == 0) {
                xView.center = CGPoint(x: self.center.x + (CGFloat(i / 2) * standardSize) + (CGFloat(i / 2) * standardPadding), y: self.center.y)
            } else {
                xView.center = CGPoint(x: self.center.x - (CGFloat(i / 2) * standardSize) - (CGFloat(i / 2) * standardPadding), y: self.center.y)
            }
            self.addSubview(xView)
            drawAction(fromPosition: xView.center, action: .Block, routeType: nil, direction: nil)
        }
    }
    
    private func drawOffensivePlayer(inPosition position: FCPlayStartPosition) -> UIView {
        let offView: UIView = drawOffensivePlayerRing(frame: CGRect(x: 0, y: 0, width: standardSize, height: standardSize), ringColor: UIColor.white)
        if (position == .Shotgun || position == .BackfieldIFormMiddle) {
            offView.center = CGPoint(x: self.center.x, y: self.center.y + (2 * (standardPadding + standardSize)))
        } else if (position == .UnderCenter) {
            offView.center = CGPoint(x: self.center.x, y: self.center.y + standardSize + standardPadding)
        } else if (position == .BackfieldIFormDeep) {
            offView.center = CGPoint(x: self.center.x, y: self.center.y + (3 * (standardPadding + standardSize)))
        } else if (position == .BackfieldPistolLeft) {
            offView.center = CGPoint(x: self.center.x - (1 * (standardPadding + standardSize)), y: self.center.y + (2 * (standardPadding + standardSize)))
        } else if (position == .BackfieldPistolRight) {
            offView.center = CGPoint(x: self.center.x + (1 * (standardPadding + standardSize)), y: self.center.y + (2 * (standardPadding + standardSize)))
        } else if (position == .SlotLeft) {
            offView.center = CGPoint(x: self.center.x - (4.5 * (standardPadding + standardSize)), y: self.center.y)
        } else if (position == .SlotRight) {
            offView.center = CGPoint(x: self.center.x + (4.5 * (standardPadding + standardSize)), y: self.center.y)
        } else if (position == .WideLeft) {
            offView.center = CGPoint(x: self.center.x - (7 * (standardPadding + standardSize)), y: self.center.y)
        } else if (position == .WideRight) {
            offView.center = CGPoint(x: self.center.x + (7 * (standardPadding + standardSize)), y: self.center.y)
        } else if (position == .TightLeft) {
            offView.center = CGPoint(x: self.center.x - (3 * (standardPadding + standardSize)), y: self.center.y + (0.5 * (standardPadding + standardSize)))
        } else if (position == .TightRight) {
            offView.center = CGPoint(x: self.center.x + (3 * (standardPadding + standardSize)), y: self.center.y + (0.5 * (standardPadding + standardSize)))
        } else {
            offView.center = self.center // LOS
        }
        self.addSubview(offView)
        return offView;
    }
    
    private func drawAction(fromPosition playerPosition: CGPoint, action: FCPlayAction!, routeType: FCPlayRouteType?, direction: FCPlayRunningDirection?) {
        if (action == .Block) {
            var startPoint: CGPoint = CGPoint(x: playerPosition.x, y: playerPosition.y - standardPadding - (standardSize / 2.0))
            var endPoint: CGPoint = CGPoint(x: startPoint.x, y: startPoint.y - (standardPadding * 2.0))
            var horizontalCrossStartPoint: CGPoint = CGPoint(x: endPoint.x - (standardPadding * 1.5), y: endPoint.y)
            var horizontalCrossEndPoint: CGPoint = CGPoint(x: endPoint.x + (standardPadding * 1.5), y: endPoint.y)
            if (direction != nil) {
                print("found a direction to handle for blocking")
                if (direction == .Right || direction == .SlantRight) {
                    startPoint = CGPoint(x: playerPosition.x + standardPadding + (standardSize / 2.0), y: playerPosition.y)
                    endPoint = CGPoint(x: startPoint.x + (standardPadding * 2.0), y: startPoint.y)
                } else if (direction == .Left || direction == .SlantLeft) {
                    startPoint = CGPoint(x: playerPosition.x - standardPadding - (standardSize / 2.0), y: playerPosition.y)
                    endPoint = CGPoint(x: startPoint.x - (standardPadding * 2.0), y: startPoint.y)
                }
                horizontalCrossStartPoint = CGPoint(x: endPoint.x, y: endPoint.y - (standardPadding * 1.5))
                horizontalCrossEndPoint = CGPoint(x: endPoint.x, y: endPoint.y + (standardPadding * 1.5))
            }
            self.layer.addSublayer(drawLine(fromPoint: startPoint, toPoint: endPoint, color: UIColor.gray))
            self.layer.addSublayer(drawLine(fromPoint: horizontalCrossStartPoint, toPoint: horizontalCrossEndPoint, color: UIColor.gray))
        } else if (action == .Rush || action == .RunRoute) {
            if (routeType != nil && routeType! != .None) {
                drawRoute(fromPosition: playerPosition, routeType: routeType!, direction: direction!)
            }
        } // else handoff - do nothing
    }
    
    private func drawRoute(fromPosition playerPosition: CGPoint, routeType: FCPlayRouteType!, direction: FCPlayRunningDirection!) {
        var startPoint: CGPoint? = nil
        var endPoint: CGPoint? = nil
        if (routeType == .Streak) {
            startPoint = CGPoint(x: playerPosition.x, y: playerPosition.y - standardPadding - (standardSize / 2.0))
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 3.0))
//            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: UIColor.yellow))
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: UIColor.yellow))
        } else if (routeType == .Post) {
            startPoint = CGPoint(x: playerPosition.x, y: playerPosition.y - standardPadding - (standardSize / 2.0))
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 3.0))
            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: UIColor.yellow))
            startPoint = endPoint!
            if (direction == .SlantRight) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2), y: startPoint!.y - (standardSize * 2))
            } else if (direction == .SlantLeft) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 2), y: startPoint!.y - (standardSize * 2))
            } else if (direction == .Right) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2), y: startPoint!.y)
            } else if (direction == .Left) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 2), y: startPoint!.y)
            }
//            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: UIColor.yellow))
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: UIColor.yellow))
        } else if (routeType == .Flat || routeType == .Sweep) {
            startPoint = playerPosition
            if (direction == .SlantLeft) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 2.5), y: startPoint!.y - (standardSize * 0.75))
            } else if (direction == .SlantRight) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2.5), y: startPoint!.y - (standardSize * 0.75))
            } else if (direction == .Right) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2.5), y: startPoint!.y - (standardSize * 0.75))
            } else {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 2.5), y: startPoint!.y - (standardSize * 0.75))
            }
//            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: UIColor.yellow))
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: UIColor.yellow))
        } else if (routeType == .Screen) {
            startPoint = CGPoint(x: playerPosition.x, y: playerPosition.y + standardPadding + (standardSize / 2.0))
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y + (standardPadding * 2.0))
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: UIColor.yellow))
        } else if (routeType == .Slant) {
            startPoint = CGPoint(x: playerPosition.x, y: playerPosition.y - standardPadding - (standardSize / 2.0))
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 1.0))
            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: UIColor.yellow))
            startPoint = endPoint!
            if (direction == .SlantRight || direction == .Right) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2.5), y: startPoint!.y - (standardSize * 1))
            } else {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 2.5), y: startPoint!.y - (standardSize * 1))
            }
//            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: UIColor.yellow))
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: UIColor.yellow))
        } else if (routeType == .Comeback) {
            startPoint = CGPoint(x: playerPosition.x, y: playerPosition.y - standardPadding - (standardSize / 2.0))
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 3.0))
            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: UIColor.yellow))
            startPoint = endPoint!
            if (direction == .SlantLeft || direction == .Left) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 0.5), y: startPoint!.y + (standardSize * 0.5))
            } else {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 0.5), y: startPoint!.y + (standardSize * 0.5))
            }
//            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: UIColor.yellow))
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: UIColor.yellow))
        } else if (routeType == .Dive) {
            startPoint = playerPosition
            if (direction == .SlantLeft) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 1.25), y: startPoint!.y - (standardSize * 2.5))
            } else if (direction == .SlantRight) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 1.25), y: startPoint!.y - (standardSize * 2.5))
            } else if (direction == .Right) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 1.25), y: startPoint!.y - (standardSize * 2.5))
            } else {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 1.25), y: startPoint!.y - (standardSize * 2.5))
            }
            //            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: UIColor.yellow))
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: UIColor.yellow))
        } else if (routeType == .Wheel) {
            if (direction == .SlantRight || direction == .Right) {
                startPoint = CGPoint(x: playerPosition.x + standardPadding + (standardSize / 2.0), y: playerPosition.y)
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2), y: startPoint!.y)
            } else {
                startPoint = CGPoint(x: playerPosition.x - standardPadding - (standardSize / 2.0), y: playerPosition.y)
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 2), y: startPoint!.y)
            }
            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: UIColor.yellow))
            startPoint = endPoint!
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 3.5))
            //            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: UIColor.yellow))
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: UIColor.yellow))
        }
    }
    
    private func drawArrow(startPoint: CGPoint, endPoint: CGPoint, color: UIColor) -> CAShapeLayer {
        let arrowhead: UIBezierPath = UIBezierPath()
        let arrowAngle: CGFloat = CGFloat(Double.pi / 4)
        arrowhead.addArrowhead(start: startPoint, end: endPoint, pointerLineLength: standardSize / 2.0, arrowAngle: arrowAngle)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = arrowhead.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        return shapeLayer
    }
    
    private func drawDefensiveLine(actions: Array<Dictionary<String, Any>>) {
        if (actions.count % 2 == 1) {
            for i in 0...actions.count {
                let xView: UIView = drawDefensivePlayerX(frame: CGRect(x: 0, y: 0, width: standardSize, height: standardSize), xColor: UIColor.white)
                if (i % 2 == 0) {
                    xView.center = CGPoint(x: self.center.x - (xView.frame.width / 2.0) + (CGFloat(i / 2) * standardSize) + (CGFloat(i / 2) * standardPadding), y: self.center.y)
                } else {
                    xView.center = CGPoint(x: self.center.x - (xView.frame.width / 2.0) - (CGFloat(i / 2) * standardSize) - (CGFloat(i / 2) * standardPadding), y: self.center.y)
                }
                self.addSubview(xView)
            }
        } else {
            for i in 0...actions.count-1 {
                let xView: UIView = drawDefensivePlayerX(frame: CGRect(x: 0, y: 0, width: standardSize, height: standardSize), xColor: UIColor.white)
                if (i % 2 == 0) {
                    xView.center = CGPoint(x: self.center.x - (standardPadding * 2.0) + ((CGFloat(i / 2) + 0.5) * standardSize) + (CGFloat(i / 2) * standardPadding), y: self.center.y)
                } else {
                    xView.center = CGPoint(x: self.center.x - (standardPadding * 2.0) - ((CGFloat(i / 2) + 0.5) * standardSize) - (CGFloat(i / 2) * standardPadding), y: self.center.y)
                }
                self.addSubview(xView)
            }
        }
    }
    
    private func drawLine(fromPoint start: CGPoint, toPoint end:CGPoint, color: UIColor) -> CAShapeLayer {
        //design the path
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        
        //design path in layer
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        return shapeLayer
    }
    
    private func drawOffensivePlayerRing(frame: CGRect, ringColor: UIColor) -> UIView
    {
        let halfSize:CGFloat = min(frame.size.width/2, frame.size.height/2)
        let desiredLineWidth:CGFloat = 2
        
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x:halfSize,y:halfSize),
            radius: CGFloat( halfSize - (desiredLineWidth/2) ),
            startAngle: CGFloat(0),
            endAngle:CGFloat(Double.pi * 2),
            clockwise: true)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = ringColor.cgColor
        shapeLayer.lineWidth = desiredLineWidth
        
        let ringView: UIView = UIView(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height))
        ringView.backgroundColor = UIColor.clear
        ringView.layer.addSublayer(shapeLayer)
        return ringView
    }
    
    private func drawDefensivePlayerX(frame: CGRect, xColor: UIColor) -> UIView
    {
        let rightTop: CGPoint = CGPoint(x: frame.width, y: 0)
        let leftTop: CGPoint = CGPoint(x: 0, y: 0)
        let leftBottom: CGPoint = CGPoint(x: frame.width, y: frame.height)
        let rightBottom: CGPoint = CGPoint(x: 0, y: frame.height)
        
        let xView: UIView = UIView(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height))
        xView.backgroundColor = UIColor.clear
        
        let a: CGFloat = CGFloat.pi / 4.0
        let x: CGFloat = xView.center.x
        let y: CGFloat = xView.center.y
        var transform: CGAffineTransform = CGAffineTransform.init(translationX: x, y: y)
        transform = transform.rotated(by: a)
        transform = transform.translatedBy(x: -x, y: -y)
    
        let topRightToBottomLeftLayer: CAShapeLayer = drawLine(fromPoint: rightTop, toPoint: leftBottom, color: xColor)
        topRightToBottomLeftLayer.setAffineTransform(transform)
        xView.layer.addSublayer(topRightToBottomLeftLayer)
        
        let topLeftToBottomRightLayer: CAShapeLayer = drawLine(fromPoint: leftTop, toPoint: rightBottom, color: xColor)
        transform = transform.inverted()
        transform = transform.translatedBy(x: x, y: y)
        topLeftToBottomRightLayer.setAffineTransform(transform)
        xView.layer.addSublayer(topLeftToBottomRightLayer)
        return xView
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(UIColor.black.cgColor)
        context!.fill(self.frame)
    }
    
    public func refreshArt() {
        
        // Horizontal guideline
        self.layer.addSublayer(drawLine(fromPoint: CGPoint(x: self.center.x, y: 0), toPoint: CGPoint(x: self.center.x, y: self.frame.height), color: UIColor.red))
        // vertical guideline
        self.layer.addSublayer(drawLine(fromPoint: CGPoint(x: 0, y: self.center.y), toPoint: CGPoint(x: self.frame.width, y: self.center.y), color: UIColor.green))
        
        if (playActions.keys.contains("OL")) {
            drawOffensiveLine()
            drawPlayerSet(actions: playActions["QB"]!)
            drawPlayerSet(actions: playActions["RB"]!)
            drawPlayerSet(actions: playActions["WR"]!)
            drawPlayerSet(actions: playActions["TE"]!)
        } else if (playActions.keys.contains("DL")) {
            drawDefensiveLine(actions: playActions["DL"]!)
        }
    }
}


var view: PlayArtView = PlayArtView(frame: CGRect(x: 0, y: 0, width: 200, height: 150))
var offActions = [
    "OL" : [
        [
            "action" : FCPlayAction.Block.rawValue,
            "startPosition" : FCPlayStartPosition.LOS.rawValue,
        ],
        [
            "action" : FCPlayAction.Block.rawValue,
            "startPosition" : FCPlayStartPosition.LOS.rawValue,
        ],
        [
            "action" : FCPlayAction.Block.rawValue,
            "startPosition" : FCPlayStartPosition.LOS.rawValue,
        ],
        [
            "action" : FCPlayAction.Block.rawValue,
            "startPosition" : FCPlayStartPosition.LOS.rawValue,
        ],
        [
            "action" : FCPlayAction.Block.rawValue,
            "startPosition" : FCPlayStartPosition.LOS.rawValue,
        ]
    ],
    "QB" : [
        [
            "action" : FCPlayAction.Handoff.rawValue,
            "startPosition" : FCPlayStartPosition.UnderCenter.rawValue,
            "route" : [
                "type" : FCPlayRouteType.None.rawValue,
                "direction" : FCPlayRunningDirection.SlantRight.rawValue
            ]
        ]
    ],
    "RB" : [
        [
            "action" : FCPlayAction.Rush.rawValue,
            "startPosition" : FCPlayStartPosition.BackfieldIFormMiddle.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Sweep.rawValue,
                "direction" : FCPlayRunningDirection.SlantRight.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.Rush.rawValue,
            "startPosition" : FCPlayStartPosition.BackfieldIFormDeep.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Dive.rawValue,
                "direction" : FCPlayRunningDirection.SlantRight.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.Rush.rawValue,
            "startPosition" : FCPlayStartPosition.BackfieldPistolLeft.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Sweep.rawValue,
                "direction" : FCPlayRunningDirection.SlantLeft.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.Rush.rawValue,
            "startPosition" : FCPlayStartPosition.BackfieldPistolRight.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Dive.rawValue,
                "direction" : FCPlayRunningDirection.SlantRight.rawValue
            ]
        ],
    ],
    "WR" : [
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.SlotLeft.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Wheel.rawValue,
                "direction" : FCPlayRunningDirection.Straight.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.WideRight.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Flat.rawValue,
                "direction" : FCPlayRunningDirection.SlantLeft.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.SlotRight.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Post.rawValue,
                "direction" : FCPlayRunningDirection.SlantLeft.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.WideLeft.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Screen.rawValue,
                "direction" : FCPlayRunningDirection.SlantRight.rawValue
            ]
        ]
    ],
    "TE" : [
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.TightLeft.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Comeback.rawValue,
                "direction" : FCPlayRunningDirection.Straight.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.TightRight.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Slant.rawValue,
                "direction" : FCPlayRunningDirection.Right.rawValue
            ]
        ]
    ]
]

//var defActions43: Dictionary<String, Array<Dictionary<String, Int>>> = [
//    "DL" : [
//        [:],
//        [:],
//        [:],
//        [:]
//    ],
//    "LB" : [
//        [:],
//        [:],
//        [:]
//    ],
//    "CB" : [
//        [:],
//        [:],
//        [:]
//    ],
//    "S" : [
//        [:]
//    ]
//]
//
//var defActions34: Dictionary<String, Array<Dictionary<String, Int>>> = [
//    "DL" : [
//        [:],
//        [:],
//        [:]
//    ],
//    "LB" : [
//        [:],
//        [:],
//        [:],
//        [:]
//    ],
//    "CB" : [
//        [:],
//        [:],
//        [:]
//    ],
//    "S" : [
//        [:]
//    ]
//]

view.playActions = offActions
view.refreshArt()
