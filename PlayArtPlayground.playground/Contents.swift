//: A UIKit based Playground for presenting user interface
  
import UIKit
import CoreFoundation

enum FCPlayTeamType : Int {
    case Offense
    case Defense
}

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
    case Angle
    
    // defensive
    case Zone
    case Man
    case Spy
}

enum FCPlayRunningDirection : Int {
    case Right
    case Left
    case SlantRight
    case SlantLeft
    case Straight
    
    case BackRight
    case BackLeft
    case BackSlantRight
    case BackSlantLeft
    case BackStraight
    
    case Stay
}

enum FCPlayAction : Int {
    // Offensive
    case Block
    case Rush
    case RunRoute
    case Pass
    case Handoff
    
    // defensive
    case Coverage
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
    case DefensiveBackfieldMLB
    case BackfieldPistolLeft
    case DefensiveBackfieldLeftCentral
    case DefensiveBackfieldLeftWide
    case BackfieldPistolRight
    case DefensiveBackfieldRightCentral
    case DefensiveBackfieldRightWide
    
    // RB only
    case BackfieldIFormDeep

    // S
    case DefensiveBackfieldDeepCenter
    case DefensiveBackfieldDeepLeftCentral
    case DefensiveBackfieldDeepLeftWide
    case DefensiveBackfieldDeepRightCentral
    case DefensiveBackfieldDeepRightWide
    
    // CB
    case DefensiveBackfieldMiddleCenter
    case DefensiveBackfieldMiddleLeftCentral
    case DefensiveBackfieldMiddleLeftWide
    case DefensiveBackfieldMiddleRightCentral
    case DefensiveBackfieldMiddleRightWide
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
    public var standardSize: CGFloat = 10.0
    public var standardPadding: CGFloat = 2.0
    public var standardLineWidth: CGFloat = 2.0
    
    public var playActions: Dictionary<String, Array<Dictionary<String, Any>>> = [:]
    
    public var routeColor: UIColor = UIColor.yellow
    public var zoneColor: UIColor = UIColor.blue
    public var spyColor: UIColor = UIColor(red:0.87, green:0.38, blue:0.65, alpha:1.00)
    public var blockColor: UIColor = UIColor.gray
    public var blitzColor: UIColor = UIColor.red
    
    public var offensiveColor: UIColor = UIColor.white
    public var defensiveColor: UIColor = UIColor.white
    
    public var shouldDrawGuidelines: Bool = false
    public var shouldDrawLineOfScrimmage: Bool = false
    
    //    Source: https://stackoverflow.com/questions/4334233/how-to-capture-uiview-to-uiimage-without-loss-of-quality-on-retina-display
    public func generateImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        return nil
    }
    
    private func drawPlayerSet(actions: Array<Dictionary<String, Any>>, teamType: FCPlayTeamType, centralPoint: CGPoint) {
        if (actions.count == 0) {
            return;
        }
        for dict in actions {
            let pView: UIView = drawPlayer(inPosition: FCPlayStartPosition(rawValue: dict["startPosition"] as! Int) ?? .TightRight, teamType: teamType, centralPoint: centralPoint)
            let action: FCPlayAction = FCPlayAction(rawValue: dict["action"] as! Int) ?? .Block
            if (dict.keys.contains("route")) {
                let routeInfo = dict["route"] as? Dictionary<String, Any>
                if (routeInfo != nil) {
                    let type: FCPlayRouteType = FCPlayRouteType(rawValue: (routeInfo!["type"] as! Int)) ?? .Flat
                    let direction: FCPlayRunningDirection = FCPlayRunningDirection(rawValue: (routeInfo!["direction"] as! Int)) ?? .Right
                    drawAction(fromPosition: pView.center, action: action, routeType: type, direction: direction)
                }
            } else {
                drawAction(fromPosition: pView.center, action: action, routeType: nil, direction: nil)
            }
        }
    }
    
    private func drawOffensiveLine(centralPoint: CGPoint) {
        for i in 0...5 {
            let xView: UIView = drawOffensivePlayerRing(frame: CGRect(x: 0, y: 0, width: standardSize, height: standardSize), ringColor: UIColor.white)
            if (i % 2 == 0) {
                xView.center = CGPoint(x: centralPoint.x + (CGFloat(i / 2) * standardSize) + (CGFloat(i / 2) * standardPadding), y: centralPoint.y)
            } else {
                xView.center = CGPoint(x: centralPoint.x - (CGFloat(i / 2) * standardSize) - (CGFloat(i / 2) * standardPadding), y: centralPoint.y)
            }
            self.addSubview(xView)
            drawAction(fromPosition: xView.center, action: .Block, routeType: nil, direction: nil)
        }
    }
    
    private func drawPlayer(inPosition position: FCPlayStartPosition, teamType: FCPlayTeamType!, centralPoint: CGPoint) -> UIView {
        let offView: UIView
        if (teamType == .Offense) {
            offView = drawOffensivePlayerRing(frame: CGRect(x: 0, y: 0, width: standardSize, height: standardSize), ringColor: offensiveColor)
        } else {
            offView = drawDefensivePlayerX(frame: CGRect(x: 0, y: 0, width: standardSize, height: standardSize), xColor: defensiveColor)
        }
        if (position == .Shotgun || position == .BackfieldIFormMiddle) {
            offView.center = CGPoint(x: centralPoint.x, y: centralPoint.y + (2 * (standardPadding + standardSize)))
        } else if (position == .UnderCenter) {
            offView.center = CGPoint(x: centralPoint.x, y: centralPoint.y + (1 * (standardPadding + standardSize)))
        } else if (position == .BackfieldIFormDeep) {
            offView.center = CGPoint(x: centralPoint.x, y: centralPoint.y + (3 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldDeepCenter) {
            offView.center = CGPoint(x: centralPoint.x, y: centralPoint.y - (6.0 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldDeepLeftCentral) {
            offView.center = CGPoint(x: centralPoint.x - (1.5 * (standardPadding + standardSize)), y: centralPoint.y - (6.0 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldDeepRightCentral) {
            offView.center = CGPoint(x: centralPoint.x + (1.5 * (standardPadding + standardSize)), y: centralPoint.y - (6.0 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldDeepLeftWide) {
            offView.center = CGPoint(x: centralPoint.x - (3.5 * (standardPadding + standardSize)), y: centralPoint.y - (6.0 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldDeepRightWide) {
            offView.center = CGPoint(x: centralPoint.x + (3.5 * (standardPadding + standardSize)), y: centralPoint.y - (6.0 * (standardPadding + standardSize)))
        } else if (position == .BackfieldPistolLeft) {
            offView.center = CGPoint(x: centralPoint.x - (1 * (standardPadding + standardSize)), y: centralPoint.y + (2 * (standardPadding + standardSize)))
        } else if (position == .BackfieldPistolRight) {
            offView.center = CGPoint(x: centralPoint.x + (1 * (standardPadding + standardSize)), y: centralPoint.y + (2 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldLeftWide) {
            offView.center = CGPoint(x: centralPoint.x - (3.25 * (standardPadding + standardSize)), y: centralPoint.y - (2 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldLeftCentral) {
            offView.center = CGPoint(x: centralPoint.x - (1.5 * (standardPadding + standardSize)), y: centralPoint.y - (2 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldMLB) {
            offView.center = CGPoint(x: centralPoint.x, y: centralPoint.y - (2 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldRightCentral) {
            offView.center = CGPoint(x: centralPoint.x + (1.5 * (standardPadding + standardSize)), y: centralPoint.y - (2 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldRightWide) {
            offView.center = CGPoint(x: centralPoint.x + (3.25 * (standardPadding + standardSize)), y: centralPoint.y - (2 * (standardPadding + standardSize)))
        } else if (position == .SlotLeft) {
            offView.center = CGPoint(x: centralPoint.x - (4.5 * (standardPadding + standardSize)), y: centralPoint.y)
        } else if (position == .SlotRight) {
            offView.center = CGPoint(x: centralPoint.x + (4.5 * (standardPadding + standardSize)), y: centralPoint.y)
        } else if (position == .WideLeft) {
            offView.center = CGPoint(x: centralPoint.x - (7 * (standardPadding + standardSize)), y: centralPoint.y)
        } else if (position == .WideRight) {
            offView.center = CGPoint(x: centralPoint.x + (7 * (standardPadding + standardSize)), y: centralPoint.y)
        } else if (position == .TightLeft) {
            offView.center = CGPoint(x: centralPoint.x - (3 * (standardPadding + standardSize)), y: centralPoint.y + (0.5 * (standardPadding + standardSize)))
        } else if (position == .TightRight) {
            offView.center = CGPoint(x: centralPoint.x + (3 * (standardPadding + standardSize)), y: centralPoint.y + (0.5 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldMiddleCenter) {
            offView.center = CGPoint(x: centralPoint.x, y: centralPoint.y - (3.5 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldMiddleLeftCentral) {
            offView.center = CGPoint(x: centralPoint.x - (4 * (standardPadding + standardSize)), y: centralPoint.y - (3.5 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldMiddleRightCentral) {
            offView.center = CGPoint(x: centralPoint.x + (4 * (standardPadding + standardSize)), y: centralPoint.y - (3.5 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldMiddleLeftWide) {
            offView.center = CGPoint(x: centralPoint.x - (6 * (standardPadding + standardSize)), y: centralPoint.y - (1.5 * (standardPadding + standardSize)))
        } else if (position == .DefensiveBackfieldMiddleRightWide) {
            offView.center = CGPoint(x: centralPoint.x + (6 * (standardPadding + standardSize)), y: centralPoint.y - (1.5 * (standardPadding + standardSize)))
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
                    horizontalCrossStartPoint = CGPoint(x: endPoint.x, y: endPoint.y - (standardPadding * 1.5))
                    horizontalCrossEndPoint = CGPoint(x: endPoint.x, y: endPoint.y + (standardPadding * 1.5))
                } else if (direction == .Left || direction == .SlantLeft) {
                    startPoint = CGPoint(x: playerPosition.x - standardPadding - (standardSize / 2.0), y: playerPosition.y)
                    endPoint = CGPoint(x: startPoint.x - (standardPadding * 2.0), y: startPoint.y)
                    horizontalCrossStartPoint = CGPoint(x: endPoint.x, y: endPoint.y - (standardPadding * 1.5))
                    horizontalCrossEndPoint = CGPoint(x: endPoint.x, y: endPoint.y + (standardPadding * 1.5))
                }
            }
            self.layer.addSublayer(drawLine(fromPoint: startPoint, toPoint: endPoint, color: blockColor))
            self.layer.addSublayer(drawLine(fromPoint: horizontalCrossStartPoint, toPoint: horizontalCrossEndPoint, color: blockColor))
        } else if (action == .Rush || action == .RunRoute || action == .Coverage) {
            if (routeType != nil && routeType! != .None) {
                drawRoute(fromPosition: playerPosition, routeType: routeType!, direction: direction!)
            }
        } else if (action == .Blitz) {
            let startPoint: CGPoint = CGPoint(x: playerPosition.x, y: playerPosition.y + standardPadding + (standardSize / 2.0))
            let targetYValue: CGFloat = playerPosition.y + (((0.9 * self.frame.height) - playerPosition.y))
            let scaleFactor: CGFloat = 0.60
//            let tempEndPoint: CGPoint = CGPoint(x: self.center.x, y: )
//            let slope: CGFloat = (tempEndPoint.y - startPoint.y) / (tempEndPoint.x - startPoint.x)
            let endPoint: CGPoint = CGPoint(x: playerPosition.x + (scaleFactor * (self.center.x - playerPosition.x)), y: playerPosition.y + (scaleFactor * (targetYValue - playerPosition.y)))
            self.layer.addSublayer(drawArrow(startPoint: startPoint, endPoint: endPoint, color: blitzColor))
        }
        // else handoff OR pass - do nothing
    }
    
    private func drawRoute(fromPosition playerPosition: CGPoint, routeType: FCPlayRouteType!, direction: FCPlayRunningDirection!) {
        var startPoint: CGPoint? = nil
        var endPoint: CGPoint? = nil
        if (routeType == .Streak) {
            startPoint = CGPoint(x: playerPosition.x, y: playerPosition.y - standardPadding - (standardSize / 2.0))
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 5.0))

            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: routeColor))
        } else if (routeType == .Post) {
            startPoint = CGPoint(x: playerPosition.x, y: playerPosition.y - standardPadding - (standardSize / 2.0))
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 3.0))
            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: routeColor))
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

            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: routeColor))
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

            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: routeColor))
        } else if (routeType == .Screen) {
            startPoint = CGPoint(x: playerPosition.x, y: playerPosition.y + standardPadding + (standardSize / 2.0))
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y + (standardPadding * 2.0))
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: routeColor))
        } else if (routeType == .Slant) {
            startPoint = CGPoint(x: playerPosition.x, y: playerPosition.y - standardPadding - (standardSize / 2.0))
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 1.0))
            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: routeColor))
            startPoint = endPoint!
            if (direction == .SlantRight || direction == .Right) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2.5), y: startPoint!.y - (standardSize * 1))
            } else {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 2.5), y: startPoint!.y - (standardSize * 1))
            }

            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: routeColor))
        } else if (routeType == .Comeback) {
            startPoint = CGPoint(x: playerPosition.x, y: playerPosition.y - standardPadding - (standardSize / 2.0))
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 3.0))
            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: routeColor))
            startPoint = endPoint!
            if (direction == .SlantLeft || direction == .Left) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 0.5), y: startPoint!.y + (standardSize * 0.5))
            } else {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 0.5), y: startPoint!.y + (standardSize * 0.5))
            }

            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: routeColor))
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
            
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: routeColor))
        } else if (routeType == .Wheel) {
            if (direction == .SlantRight || direction == .Right) {
                startPoint = CGPoint(x: playerPosition.x + standardPadding + (standardSize / 2.0), y: playerPosition.y)
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2), y: startPoint!.y)
            } else {
                startPoint = CGPoint(x: playerPosition.x - standardPadding - (standardSize / 2.0), y: playerPosition.y)
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 2), y: startPoint!.y)
            }
            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: routeColor))
            startPoint = endPoint!
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 3.5))
            
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: routeColor))
        } else if (routeType == .Angle) {
            if (direction == .SlantRight || direction == .Right) {
                startPoint = CGPoint(x: playerPosition.x + standardPadding + (standardSize / 2.0), y: playerPosition.y)
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 3), y: startPoint!.y - (standardSize * 2.5))
            } else {
                startPoint = CGPoint(x: playerPosition.x - standardPadding - (standardSize / 2.0), y: playerPosition.y)
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 3), y: startPoint!.y - (standardSize * 2.5))
            }
            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: routeColor))
            startPoint = endPoint!
            if (direction == .SlantRight || direction == .Right) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 2), y: startPoint!.y - (standardSize * 2.5))
            } else {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2), y: startPoint!.y - (standardSize * 2.5))
            }
            self.layer.addSublayer(drawArrow(startPoint: startPoint!, endPoint: endPoint!, color: routeColor))
        } else if (routeType == .Zone) {
            startPoint = playerPosition
            if (direction == .SlantLeft) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 1.25), y: startPoint!.y + (standardSize * 2.5))
            } else if (direction == .SlantRight) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2.25), y: startPoint!.y + (standardSize * 2.5))
            } else if (direction == .Right) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2.25), y: startPoint!.y + (standardSize * 2.5))
            } else if (direction == .SlantLeft) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 1.25), y: startPoint!.y + (standardSize * 2.5))
            } else if (direction == .BackSlantLeft) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 1.25), y: startPoint!.y - (standardSize * 2.5))
            } else if (direction == .BackSlantRight) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 1.25), y: startPoint!.y - (standardSize * 2.5))
            } else if (direction == .BackRight) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2.25), y: startPoint!.y - (standardSize * 2.5))
            } else if (direction == .BackStraight) {
                endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 2.5))
            } else { // straight
                endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y + (standardSize * 2.5))
            }
            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: zoneColor))
            self.layer.addSublayer(drawBubble(centerPoint: endPoint!, color: zoneColor))
        } else if (routeType == .Spy) {
            startPoint = playerPosition
            if (direction == .Stay) {
                self.layer.addSublayer(drawBubble(centerPoint: startPoint!, color: spyColor))
                return;
            }
            if (direction == .SlantLeft) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 1.25), y: startPoint!.y + (standardSize * 1.5))
            } else if (direction == .SlantRight) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2.25), y: startPoint!.y + (standardSize * 1.5))
            } else if (direction == .Right) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2.25), y: startPoint!.y + (standardSize * 1.5))
            } else if (direction == .SlantLeft) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 1.25), y: startPoint!.y + (standardSize * 1.5))
            } else if (direction == .BackSlantLeft) {
                endPoint = CGPoint(x: startPoint!.x - (standardSize * 1.25), y: startPoint!.y - (standardSize * 1.5))
            } else if (direction == .BackSlantRight) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 1.25), y: startPoint!.y - (standardSize * 1.5))
            } else if (direction == .BackRight) {
                endPoint = CGPoint(x: startPoint!.x + (standardSize * 2.25), y: startPoint!.y - (standardSize * 1.5))
            } else if (direction == .BackStraight) {
                endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - (standardSize * 1.5))
            } else { // straight
                endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y + (standardSize * 1.5))
            }
            self.layer.addSublayer(drawLine(fromPoint: startPoint!, toPoint: endPoint!, color: spyColor))
            self.layer.addSublayer(drawBubble(centerPoint: endPoint!, color: spyColor))
        }
    }
    
    private func drawBubble(centerPoint: CGPoint, color: UIColor) -> CAShapeLayer {
        let width: CGFloat = (standardSize * 4.2)
        let height: CGFloat = (standardSize * 2.7)
        let ovalRect: CGRect = CGRect(x: centerPoint.x - (width / 2.0), y: centerPoint.y - (height / 2.0), width: width, height: height)
        let path: UIBezierPath = UIBezierPath(ovalIn: ovalRect)
        path.move(to: centerPoint)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = color.withAlphaComponent(0.55).cgColor
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = standardLineWidth
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        return shapeLayer
    }
    
    private func drawArrow(startPoint: CGPoint, endPoint: CGPoint, color: UIColor) -> CAShapeLayer {
        let arrowhead: UIBezierPath = UIBezierPath()
        let arrowAngle: CGFloat = CGFloat(Double.pi / 4)
        arrowhead.addArrowhead(start: startPoint, end: endPoint, pointerLineLength: standardSize / 2.0, arrowAngle: arrowAngle)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = arrowhead.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = standardLineWidth
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        return shapeLayer
    }
    
    private func drawDefensiveLine(actions: Array<Dictionary<String, Any>>, centralPoint: CGPoint) {
        if (actions.count % 2 == 1) {
            for i in 0..<actions.count {
                let xView: UIView = drawDefensivePlayerX(frame: CGRect(x: 0, y: 0, width: standardSize, height: standardSize), xColor: UIColor.white)
                if (i % 2 == 0) {
                    xView.center = CGPoint(x: centralPoint.x + ((CGFloat(i / 2) + CGFloat(i % 2))) * ((standardSize + standardPadding) * 2.5), y: centralPoint.y)
                } else {
                    xView.center = CGPoint(x: centralPoint.x - ((CGFloat(i / 2) + CGFloat(i % 2))) * ((standardSize + standardPadding) * 2.5), y: centralPoint.y)
                }
                self.addSubview(xView)
                drawAction(fromPosition: xView.center, action: .Blitz, routeType: .None, direction: nil)
            }
        } else {
            for i in 0..<actions.count {
                let xView: UIView = drawDefensivePlayerX(frame: CGRect(x: 0, y: 0, width: standardSize, height: standardSize), xColor: UIColor.white)
                if (i % 2 == 0) {
                    xView.center = CGPoint(x: centralPoint.x + (0.5 + ((CGFloat(i / 2) + 0.5)) * (standardSize + (standardPadding * 3.0))), y: centralPoint.y)
                } else {
                    xView.center = CGPoint(x: centralPoint.x - (0.5 + ((CGFloat(i / 2) + 0.5)) * (standardSize + (standardPadding * 3.0))), y: centralPoint.y)
                }
                self.addSubview(xView)
                drawAction(fromPosition: xView.center, action: .Blitz, routeType: .None, direction: nil)
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
        shapeLayer.lineWidth = standardLineWidth
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        return shapeLayer
    }
    
    private func drawOffensivePlayerRing(frame: CGRect, ringColor: UIColor) -> UIView
    {
        let halfSize:CGFloat = min(frame.size.width/2, frame.size.height/2)
        let desiredLineWidth:CGFloat = standardLineWidth
        
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
        
        let xPath: UIBezierPath = UIBezierPath()
        xPath.move(to: xView.center)
        xPath.addLine(to: rightTop)
        xPath.move(to: xView.center)
        xPath.addLine(to: rightBottom)
        
        xPath.move(to: xView.center)
        xPath.addLine(to: leftTop)
        xPath.move(to: xView.center)
        xPath.addLine(to: leftBottom)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = xPath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = xColor.cgColor
        shapeLayer.lineWidth = standardLineWidth
        xView.layer.addSublayer(shapeLayer)
        
        return xView
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(UIColor(red:0.31, green:0.39, blue:0.29, alpha:1.00).cgColor)
        context!.fill(self.frame)
    }
    
    public func refreshArt() {
        if (self.layer.sublayers != nil && self.layer.sublayers!.count > 0) {
            for layer: CALayer in self.layer.sublayers! {
                layer.removeFromSuperlayer()
            }
        }
        for view in self.subviews {
            view.removeFromSuperview()
        }

        if (shouldDrawGuidelines) {
            // vertical guideline
            self.layer.addSublayer(drawLine(fromPoint: CGPoint(x: self.center.x, y: 0), toPoint: CGPoint(x: self.center.x, y: self.frame.height), color: UIColor.red))
            // horizontal guideline
            self.layer.addSublayer(drawLine(fromPoint: CGPoint(x: 0, y: self.center.y), toPoint: CGPoint(x: self.frame.width, y: self.center.y), color: UIColor.green))
        }
        
        var centralPoint: CGPoint = self.center
        if (playActions.keys.contains("OL")) {
            centralPoint = self.center
            drawOffensiveLine(centralPoint: centralPoint)
            drawPlayerSet(actions: playActions["QB"]!, teamType: .Offense, centralPoint: centralPoint)
            drawPlayerSet(actions: playActions["RB"]!, teamType: .Offense, centralPoint: centralPoint)
            drawPlayerSet(actions: playActions["WR"]!, teamType: .Offense, centralPoint: centralPoint)
            drawPlayerSet(actions: playActions["TE"]!, teamType: .Offense, centralPoint: centralPoint)
        } else if (playActions.keys.contains("DL")) {
            centralPoint = CGPoint(x: self.center.x, y: self.center.y + (self.frame.height / 4.0))
            drawDefensiveLine(actions: playActions["DL"]!, centralPoint: centralPoint)
            drawPlayerSet(actions: playActions["LB"]!, teamType: .Defense, centralPoint: centralPoint)
            drawPlayerSet(actions: playActions["CB"]!, teamType: .Defense, centralPoint: centralPoint)
            drawPlayerSet(actions: playActions["S"]!, teamType: .Defense, centralPoint: centralPoint)
        }
        // LOS
        if (shouldDrawLineOfScrimmage) {
            self.layer.addSublayer(drawLine(fromPoint: CGPoint(x: 0, y: centralPoint.y + ((standardSize / 2.0) + standardPadding)), toPoint: CGPoint(x: self.frame.width, y: centralPoint.y + ((standardSize / 2.0) + standardPadding)), color: UIColor.lightText))
        }
    }
}

var rocketToss = [
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
            "action" : FCPlayAction.Rush.rawValue,
            "startPosition" : FCPlayStartPosition.UnderCenter.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Sweep.rawValue,
                "direction" : FCPlayRunningDirection.SlantRight.rawValue
            ]
        ]
    ],
    "RB" : [
        [
            "action" : FCPlayAction.Rush.rawValue,
            "startPosition" : FCPlayStartPosition.BackfieldIFormDeep.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Sweep.rawValue,
                "direction" : FCPlayRunningDirection.SlantRight.rawValue
            ]
        ]
    ],
    "WR" : [
        [
            "action" : FCPlayAction.Block.rawValue,
            "startPosition" : FCPlayStartPosition.WideLeft.rawValue,
            "route" : [
                "type" : FCPlayRouteType.None.rawValue,
                "direction" : FCPlayRunningDirection.Straight.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.Block.rawValue,
            "startPosition" : FCPlayStartPosition.WideRight.rawValue,
            "route" : [
                "type" : FCPlayRouteType.None.rawValue,
                "direction" : FCPlayRunningDirection.Straight.rawValue
            ]
        ]
    ],
    "TE" : [
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.TightLeft.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Sweep.rawValue,
                "direction" : FCPlayRunningDirection.Right.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.Block.rawValue,
            "startPosition" : FCPlayStartPosition.TightRight.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Sweep.rawValue,
                "direction" : FCPlayRunningDirection.Right.rawValue
            ]
        ]
    ]
]

var view: PlayArtView = PlayArtView(frame: CGRect(x: 0, y: 0, width: 200, height: 150))
view.playActions = rocketToss
view.refreshArt()
view.generateImage()

var fourVerts = [
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
            "action" : FCPlayAction.Pass.rawValue,
            "startPosition" : FCPlayStartPosition.Shotgun.rawValue,
            "route" : [
                "type" : FCPlayRouteType.None.rawValue,
                "direction" : FCPlayRunningDirection.Straight.rawValue
            ]
        ]
    ],
    "RB" : [
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.BackfieldPistolRight.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Angle.rawValue,
                "direction" : FCPlayRunningDirection.Right.rawValue
            ]
        ]
    ],
    "WR" : [
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.SlotRight.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Streak.rawValue,
                "direction" : FCPlayRunningDirection.Straight.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.WideRight.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Comeback.rawValue,
                "direction" : FCPlayRunningDirection.SlantRight.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.SlotLeft.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Post.rawValue,
                "direction" : FCPlayRunningDirection.SlantRight.rawValue
            ]
        ],
        [
            "action" : FCPlayAction.RunRoute.rawValue,
            "startPosition" : FCPlayStartPosition.WideLeft.rawValue,
            "route" : [
                "type" : FCPlayRouteType.Comeback.rawValue,
                "direction" : FCPlayRunningDirection.SlantLeft.rawValue
            ]
        ]
    ],
    "TE" : [
        
    ]
]
view.playActions = fourVerts
view.refreshArt()
view.generateImage()

//var offActions = [
//    "OL" : [
//        [
//            "action" : FCPlayAction.Block.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ],
//        [
//            "action" : FCPlayAction.Block.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ],
//        [
//            "action" : FCPlayAction.Block.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ],
//        [
//            "action" : FCPlayAction.Block.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ],
//        [
//            "action" : FCPlayAction.Block.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ]
//    ],
//    "QB" : [
//        [
//            "action" : FCPlayAction.Handoff.rawValue,
//            "startPosition" : FCPlayStartPosition.UnderCenter.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.None.rawValue,
//                "direction" : FCPlayRunningDirection.SlantRight.rawValue
//            ]
//        ]
//    ],
//    "RB" : [
//        [
//            "action" : FCPlayAction.Rush.rawValue,
//            "startPosition" : FCPlayStartPosition.BackfieldIFormMiddle.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Sweep.rawValue,
//                "direction" : FCPlayRunningDirection.SlantRight.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Rush.rawValue,
//            "startPosition" : FCPlayStartPosition.BackfieldIFormDeep.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Dive.rawValue,
//                "direction" : FCPlayRunningDirection.SlantRight.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Rush.rawValue,
//            "startPosition" : FCPlayStartPosition.BackfieldPistolLeft.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Sweep.rawValue,
//                "direction" : FCPlayRunningDirection.SlantLeft.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Rush.rawValue,
//            "startPosition" : FCPlayStartPosition.BackfieldPistolRight.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Dive.rawValue,
//                "direction" : FCPlayRunningDirection.SlantRight.rawValue
//            ]
//        ],
//    ],
//    "WR" : [
//        [
//            "action" : FCPlayAction.RunRoute.rawValue,
//            "startPosition" : FCPlayStartPosition.SlotLeft.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Wheel.rawValue,
//                "direction" : FCPlayRunningDirection.Straight.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.RunRoute.rawValue,
//            "startPosition" : FCPlayStartPosition.WideRight.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Flat.rawValue,
//                "direction" : FCPlayRunningDirection.SlantLeft.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.RunRoute.rawValue,
//            "startPosition" : FCPlayStartPosition.SlotRight.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Post.rawValue,
//                "direction" : FCPlayRunningDirection.SlantLeft.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.RunRoute.rawValue,
//            "startPosition" : FCPlayStartPosition.WideLeft.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Screen.rawValue,
//                "direction" : FCPlayRunningDirection.SlantRight.rawValue
//            ]
//        ]
//    ],
//    "TE" : [
//        [
//            "action" : FCPlayAction.RunRoute.rawValue,
//            "startPosition" : FCPlayStartPosition.TightLeft.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Comeback.rawValue,
//                "direction" : FCPlayRunningDirection.Straight.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.RunRoute.rawValue,
//            "startPosition" : FCPlayStartPosition.TightRight.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Slant.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ]
//    ]
//]
//view.playActions = offActions
//view.refreshArt()

//var defActions43: Dictionary<String, Array<Dictionary<String, Any>>> = [
//    "DL" : [
//        [
//            "action" : FCPlayAction.Blitz.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ],
//        [
//            "action" : FCPlayAction.Blitz.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ],
//        [
//            "action" : FCPlayAction.Blitz.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ],
//        [
//            "action" : FCPlayAction.Blitz.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ]
//    ],
//    "LB" : [
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldMLB.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Spy.rawValue,
//                "direction" : FCPlayRunningDirection.Stay.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Blitz.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldRightWide.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.None.rawValue,
//                "direction" : FCPlayRunningDirection.SlantRight.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldLeftWide.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Zone.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ]
//    ],
//    "CB" : [
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldMiddleCenter.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Zone.rawValue,
//                "direction" : FCPlayRunningDirection.BackSlantRight.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldMiddleLeftCentral.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Zone.rawValue,
//                "direction" : FCPlayRunningDirection.BackRight.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldMiddleRightCentral.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Zone.rawValue,
//                "direction" : FCPlayRunningDirection.BackLeft.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldMiddleRightWide.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Man.rawValue,
//                "direction" : FCPlayRunningDirection.BackSlantLeft.rawValue
//            ]
//        ]
//    ],
//    "S" : [
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldDeepLeftWide.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Zone.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldDeepRightWide.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Man.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ]
//    ]
//]
//
//view.playActions = defActions43
//view.refreshArt()


//var defActions34: Dictionary<String, Array<Dictionary<String, Any>>> = [
//    "DL" : [
//        [
//            "action" : FCPlayAction.Blitz.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ],
//        [
//            "action" : FCPlayAction.Blitz.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ],
//        [
//            "action" : FCPlayAction.Blitz.rawValue,
//            "startPosition" : FCPlayStartPosition.LOS.rawValue,
//        ]
//    ],
//    "LB" : [
//        [
//            "action" : FCPlayAction.Blitz.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldRightCentral.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Zone.rawValue,
//                "direction" : FCPlayRunningDirection.Straight.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldLeftCentral.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Zone.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldRightWide.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Man.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldLeftWide.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Man.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ]
//    ],
//    "CB" : [
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldMiddleLeftWide.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Zone.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldMiddleCenter.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Man.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldMiddleLeftCentral.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Zone.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldMiddleRightCentral.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Zone.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldMiddleRightWide.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Man.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ]
//    ],
//    "S" : [
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldDeepLeftWide.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Zone.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ],
//        [
//            "action" : FCPlayAction.Coverage.rawValue,
//            "startPosition" : FCPlayStartPosition.DefensiveBackfieldDeepRightWide.rawValue,
//            "route" : [
//                "type" : FCPlayRouteType.Man.rawValue,
//                "direction" : FCPlayRunningDirection.Right.rawValue
//            ]
//        ]
//    ]
//]
//
//view.playActions = defActions34
//view.refreshArt()
