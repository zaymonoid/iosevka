import Foundation

enum RotationAngle {
  case degrees0
  case degrees90
  case degrees180
  case degrees270
}

func nextRotation(of rotation: RotationAngle) -> RotationAngle {
  switch rotation {
  case .degrees0: return .degrees90
  case .degrees90: return .degrees180
  case .degrees180: return .degrees270
  case .degrees270: return .degrees0
  }
}

/// The rotation that undoes `rotation`.
func inverseRotation(of rotation: RotationAngle) -> RotationAngle {
  switch rotation {
  case .degrees0: return .degrees0
  case .degrees90: return .degrees270
  case .degrees180: return .degrees180
  case .degrees270: return .degrees90
  }
}
