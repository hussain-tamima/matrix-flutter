/// Room-state types for an in-room call.
///
/// Add both to `Client.importantStateEvents` before `Client.init`. Otherwise
/// the SDK drops them while a room is only partially loaded, and nobody else
/// can see the call.
const groupCallEventType = 'io.elementx.call';
const groupCallMemberEventType = 'io.elementx.call.member';

/// Element Web rings a room call from this timeline event, not from
/// `io.elementx.call`. The referenced membership event must already exist.
const rtcNotificationEventType = 'org.matrix.msc4075.rtc.notification';

/// Decline of an [rtcNotificationEventType], referenced with `m.reference`.
const rtcDeclineEventType = 'org.matrix.msc4310.rtc.decline';

/// Encrypted to-device event carrying one participant's LiveKit media key.
const callEncryptionKeysEventType = 'io.element.call.encryption_keys';

/// Room-scoped Element Call slot (`application#call_id` with an empty id).
const rtcRoomSlotId = 'm.call#';

/// Slot the LiveKit JWT service uses for a room call. Legacy membership
/// still publishes an empty `call_id`.
const rtcJwtSlotId = 'm.call#ROOM';

const rtcNotificationLifetimeMs = 90000;

/// Legacy MatrixRTC membership. Element Web shows a room call from this state.
const matrixRtcMemberEventType = 'org.matrix.msc3401.call.member';

/// How long a published membership stays live, measured from `created_ts`.
const matrixRtcMemberExpiresMs = 4 * 60 * 60 * 1000;
